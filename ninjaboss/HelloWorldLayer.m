//
//  HelloWorldLayer.m
//  ninjaboss
//
//  Created by Shawn Wi on 7/8/12.
//  Copyright __MadPlusOne__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"
#import "GameOver.h"

// HelloWorldLayer implementation
@implementation HelloWorldHud

-(id) init
{
    if ((self = [super init])) {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        label = [CCLayer labelWithString:@"0" dimensions:CGSizeMake(50, 20)
                               alignment:UITextAlignmentRight fontName:@"Verdana-Bold" 
                                fontSize:18.0];
        label.color = ccc3(0,0,0);
        int margin = 10;
        label.position = ccp(winSize.width - (label.contentSize.width/2) 
                             - margin, label.contentSize.height/2 + margin);
        [self addChild:label];
    }
    return self;
}

- (void)numCollectedChanged:(int)numCollected {
    [label setString:[NSString stringWithFormat:@"%d", numCollected]];
}
@end


@implementation HelloWorldLayer
@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize proto = _proto;
@synthesize m = _m;
@synthesize fore = _fore;
@synthesize gameLayer = _gameLayer;
@synthesize mode = _mode;
@synthesize numCollected = _numCollected;
@synthesize hud = _hud;
@synthesize setscale;



+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
    
	// add layer as a child to scene
	[scene addChild: layer];
	
    // 
    HelloWorldHud *hud = [HelloWorldHud node];    
    [scene addChild: hud];
    
    layer.hud = hud;
    
	// return the scene
	return scene;
}

// cuts to a certain part of scene
-(void) setCenterOfScreen:(CGPoint) position{
    CGSize screenSize=[[CCDirector sharedDirector]winSize];
    int x = MAX(position.x, screenSize.width/2);
    int y = MAX(position.y, screenSize.height/2);
    x = MIN(x, _tileMap.mapSize.width*_tileMap.tileSize.width - screenSize.width/2);
    y = MIN(y, _tileMap.mapSize.height*_tileMap.tileSize.height - screenSize.height/2);
    CGPoint goodPoint = ccp(x,y);
    CGPoint centerOfScreen = ccp(screenSize.width/2,screenSize.height/2);
    CGPoint difference = ccpSub(centerOfScreen, goodPoint);
    self.position = difference;
}

// a method to move the enemy toward the player
- (void) animateEnemy:(CCSprite*)enemy
{
    // speed of the enemy
    ccTime actualDuration = 0.3;
    
    //rotate to face the player
    CGPoint diff = ccpSub(_proto.position,enemy.position);
    float angleRadians = atanf((float)diff.y / (float)diff.x);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    if (diff.x < 0) {
        cocosAngle += 180;
    }
    enemy.rotation = cocosAngle;
    
    // creates actions
    id actionMove = [CCMoveBy actionWithDuration:actualDuration
                                        position:ccpMult(ccpNormalize(ccpSub(_proto.position,enemy.position)), 10)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self
                                             selector:@selector(enemyMoveFinished:)];
    [enemy runAction:
     [CCSequence actions:actionMove, actionMoveDone, nil]];
}

// adds enemies
-(void)addEnemyAtX:(int)x y:(int)y {
    CCSprite *enemy = [CCSprite spriteWithFile:@"enemy1.png"];
    enemy.position = ccp(x, y);
    [self addChild:enemy];
    [self animateEnemy:enemy];
}

// quantifies enemy moves
- (void) enemyMoveFinished:(id)sender {
    CCSprite *enemy = (CCSprite *)sender;
    [self animateEnemy: enemy];
}

-(id) init
{
    if( (self=[super init] )) {
        
        // initializes mode
        _mode = 0;
        
        // initializes map (with accompanying layers)
        self.isTouchEnabled = YES;
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"gamemap.tmx"];
        self.background = [_tileMap layerNamed:@"Background"];
        self.m = [_tileMap layerNamed:@"m"];
        _m.visible = NO;
        self.fore = [_tileMap layerNamed:@"fore"];
        CCTMXObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objects != nil, @"'Objects' object group not found");
        NSMutableDictionary *spawnPoint = [objects objectNamed:@"spawnpt"];        
        NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
        int x = [[spawnPoint valueForKey:@"x"] intValue];
        int y = [[spawnPoint valueForKey:@"y"] intValue];
        
        // initializes ninja
        self.proto = [CCSprite spriteWithFile:@"ninjabro.png"];
        _proto.position = ccp(x, y);
        [self addChild:_proto];
        
        // initializes minimap
        self.setscale = [CCSprite spriteWithFile:@"gamemap.tmx"];
        [setscale setScale:0.2];
        
        // initializes enemies
        NSMutableDictionary * Espawn;
        for (Espawn in [objects objects]) {
            if ([[Espawn valueForKey:@"enemy"] intValue] == 1){
                x = [[Espawn valueForKey:@"x"] intValue];
                y = [[Espawn valueForKey:@"y"] intValue];
                [self addEnemyAtX:x y:y];
            }
        }
        
        // you need to put these initializations before you add the enemies,
        // because addEnemyAtX:y: uses these arrays.
        _enemies = [[NSMutableArray alloc] init];
        _projectiles = [[NSMutableArray alloc] init];
        [self schedule:@selector(testCollisions:)];
        
        // defines the buttons
        CCMenuItem *on;
        CCMenuItem *off;
        on = [CCMenuItemImage itemFromNormalImage:@"projectile-button-on.png"
                                     selectedImage:@"projectile-button-on.png"
                                           target:nil 
                                         selector:nil];
        off = [CCMenuItemImage itemFromNormalImage:@"projectile-button-off.png"
                                      selectedImage:@"projectile-button-off.png"
                                            target:nil 
                                          selector:nil];
        CCMenuItemToggle *toggleItem = [CCMenuItemToggle itemWithTarget:self
                                                               selector:@selector(projectileButtonTapped:) 
                                                                  items:off, on, nil];
        CCMenu *toggleMenu = [CCMenu menuWithItems:toggleItem, nil];
        toggleMenu.position = ccp(100, 32);
        [self addChild:toggleMenu];
        
        // positions map (?)
        [self addChild:_tileMap z:-1];
        
        // enables sound
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"TileMap.caf"];
        // matches action with sound
        [[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
        [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.caf"];
        [[SimpleAudioEngine sharedEngine] playEffect:@"move.caf"];
        
    }
    return self;
}

// connects coordinates with tile map
- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}

// registers with phone hardware for typing
-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self 
                                                     priority:0 swallowsTouches:YES];
}

// initially gets touch as input
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

// sets player position
-(void)setPlayerPosition:(CGPoint)position {
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_m tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            // ensures a collision-no breakthrough for the player
            NSString *collision = [properties valueForKey:@"Collidable"];
            if (collision && [collision compare:@"True"] == NSOrderedSame) {
                return;
            }
            // eats up the cacti
            NSString *collectable = [properties valueForKey:@"Collectable"];
            if (collectable && [collectable compare:@"True"] == NSOrderedSame) {
                [_m removeTileAt:tileCoord];
                [_fore removeTileAt:tileCoord];
            }
        }
    }
    // updates counter
    self.numCollected++;
    [_hud numCollectedChanged:_numCollected];
    
    // makes position of player
	_proto.position = position;
    
    
}

// enables touch
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // isolates movement
    if (_mode == 0) {
        
        // where's the touch?
        CGPoint touchLocation = [touch locationInView: [touch view]];		
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // initializes player position
        CGPoint playerPos = _proto.position;
        CGPoint diff = ccpSub(touchLocation, playerPos);
        
        // 
        if (abs(diff.x) > abs(diff.y)) {
            if (diff.x > 0) {
                playerPos.x += _tileMap.tileSize.width;
            } else {
                playerPos.x -= _tileMap.tileSize.width; 
            }    
        }
        // 
        else {
            if (diff.y > 0) {
                playerPos.y += _tileMap.tileSize.height;
            } 
            else {
                playerPos.y -= _tileMap.tileSize.height;
            }
        }
        
        // player should be on the screen, bro!!!
        if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
            playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
            playerPos.y >= 0 &&
            playerPos.x >= 0 ) 
        {
            [self setPlayerPosition:playerPos];
        }
        
        [self setCenterOfScreen:_proto.position];
    } 
    // throws ninja stars
    else {
        // finds where the touch is
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // create a projectile and put it at the player's location
        CCSprite *projectile = [CCSprite spriteWithFile:@"Projectile.png"];
        projectile.position = _proto.position;
        [self addChild:projectile];
        
        // determine where to shoot
        int realX;
        
        // shooting left or right?
        CGPoint diff = ccpSub(touchLocation, _proto.position);
        if (diff.x > 0)
        {
            realX = (_tileMap.mapSize.width * _tileMap.tileSize.width) +
            (projectile.contentSize.width/2);
        } else {
            realX = -(_tileMap.mapSize.width * _tileMap.tileSize.width) -
            (projectile.contentSize.width/2);
        }
        float ratio = (float) diff.y / (float) diff.x;
        int realY = ((realX - projectile.position.x) * ratio) + projectile.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // determines shooting speed
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 480/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // moves projectile
        id actionMoveDone = [CCCallFuncN actionWithTarget:self
                                selector:@selector(projectileMoveFinished:)];
        [projectile runAction:
         [CCSequence actionOne:
          [CCMoveTo actionWithDuration: realMoveDuration
                              position: realDest]
                           two: actionMoveDone]];
        // at the end of the launch projectiles section
        [_projectiles addObject:projectile];
    }
}


// victory scene
- (void) win {
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"You Win!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

// game over scene
- (void) lose {
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"You Lose!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

// makes sure projectile hit = enemy disappearance
- (void)testCollisions:(ccTime)dt {
    
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    
    // iterate through projectiles
    for (CCSprite *projectile in _projectiles) {
        CGRect projectileRect = CGRectMake(
                                           projectile.position.x - (projectile.contentSize.width/2),
                                           projectile.position.y - (projectile.contentSize.height/2),
                                           projectile.contentSize.width,
                                           projectile.contentSize.height);
        
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        
        // iterate through enemies, see if any intersect with current projectile
        for (CCSprite *target in _enemies) {
            CGRect targetRect = CGRectMake(
                                           target.position.x - (target.contentSize.width/2),
                                           target.position.y - (target.contentSize.height/2),
                                           target.contentSize.width,
                                           target.contentSize.height);
            
            if (CGRectIntersectsRect(projectileRect, targetRect)) {
                [targetsToDelete addObject:target];
            }
        }
        
        // delete all hit enemies
        for (CCSprite *target in targetsToDelete) {
            [_enemies removeObject:target];
            [self removeChild:target cleanup:YES];
        }
        
        if (targetsToDelete.count > 0) {
            // add the projectile to the list of ones to remove
            [projectilesToDelete addObject:projectile];
        }
        [targetsToDelete release];
    }
    
    // remove all the colliding projectiles
    for (CCSprite *projectile in projectilesToDelete) {
        [_projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    [projectilesToDelete release];
    
    // suppose the targets touch our boss hero?
    for (CCSprite *target in _enemies) {
        CGRect targetRect = CGRectMake(target.position.x - (target.contentSize.width/2),
                                       target.position.y - (target.contentSize.height/2),
                                       target.contentSize.width,
                                       target.contentSize.height);
        if (CGRectContainsPoint(targetRect, _proto.position)) {
            [self lose];
        }
    }
}

// clean-up
- (void) projectileMoveFinished:(id)sender {
    CCSprite *sprite = (CCSprite *)sender;
    [self removeChild:sprite cleanup:YES];
    // cleans up projectiles
    [_projectiles removeObject:sprite];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	self.tileMap = nil;
    self.background = nil;
    self.proto = nil;
    self.m = nil;
	self.fore = nil;
    
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
