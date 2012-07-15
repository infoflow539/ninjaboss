//
//  HelloWorldLayer.h
//  ninjaboss
//
//  Created by Patrick Lu on 7/8/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// notifies when ninja consumes cacti
@interface HelloWorldHud : CCLayer
{   
    CCLabelTTF *label;
}

- (void)numCollectedChanged:(int)numCollected;
@end

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
    CCTMXTiledMap *_tileMap;
    CCTMXLayer *_background;
    CCSprite *_proto;
    CCTMXLayer *_m;
    CCTMXLayer *_fore;
    HelloWorldLayer *_gameLayer;
    int _mode;
    NSMutableArray *_enemies;
    NSMutableArray *_projectiles;
    int _numCollected;
    HelloWorldHud *_hud;
    CCSprite *setscale;
}

@property (nonatomic, retain) CCTMXTiledMap *tileMap;
@property (nonatomic, retain) CCTMXLayer *background;
@property (nonatomic, retain) CCSprite *proto;
@property (nonatomic, retain) CCTMXLayer *m;
@property (nonatomic, retain) CCTMXLayer *fore;
@property (nonatomic, assign) HelloWorldLayer *gameLayer;
@property (nonatomic, assign) int mode;
@property (nonatomic, assign) int numCollected;
@property (nonatomic, retain) HelloWorldHud *hud;
@property (nonatomic, retain) CCSprite *setscale;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
