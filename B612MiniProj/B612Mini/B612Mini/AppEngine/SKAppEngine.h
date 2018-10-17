//
//  SKAppEngine.h
//  B612Mini
//
//  Created by hsg2510 on 2018. 10. 17..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKAppEngine : NSObject

@property (nonatomic, readonly) EAGLContext *context;
@property (nonatomic, readonly) BOOL isStarted;


+ (id)sharedAppEngine;
- (void)initWithContext:(EAGLContext *)aEAGLContext EAGLLayer:(CAEAGLLayer *)aLayer;
- (void)setMainTextureWithPath:(char *)aPath;
- (void)render;
- (void)resumeEngine;
- (void)pauseEngine;

@end

NS_ASSUME_NONNULL_END
