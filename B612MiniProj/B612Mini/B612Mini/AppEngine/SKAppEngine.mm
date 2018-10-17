//
//  SKAppEngine.m
//  B612Mini
//
//  Created by hsg2510 on 2018. 10. 17..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKAppEngine.h"
#import "CustomRenderingEngine.hpp"
#import "SKQueueDispatcher.h"
#import "Vector2.h"
#import "Vector4.h"
#include <vector>

using namespace kuru;
using namespace gameplay;
using namespace std;

@implementation SKAppEngine
{
    EAGLContext *mContext;
    char *mMainTexturePath;
    BOOL mShouldUpdateFrameBuffer;
    BOOL mIsStarted;
    
    CAEAGLLayer *mLayer;
}

@synthesize context = mContext;
@synthesize isStarted = mIsStarted;


#pragma mark - init, dealloc


+ (id)sharedAppEngine
{
    static SKAppEngine *sSharedAppEngine = nil;
    static dispatch_once_t sOnceToken;
    
    dispatch_once(&sOnceToken, ^{
        sSharedAppEngine = [[self alloc] init];
    });
    
    return sSharedAppEngine;
}

- (void)dealloc
{
    if ([EAGLContext currentContext] == mContext)
    {
        [EAGLContext setCurrentContext:nil];
    }
}


#pragma mark - public


- (void)initWithContext:(EAGLContext *)aEAGLContext EAGLLayer:(CAEAGLLayer *)aLayer
{
    [[SKQueueDispatcher sharedDispatcher] runAsynchronouslyOnGLRenderingQueue:^{
        mContext = aEAGLContext;
        mShouldUpdateFrameBuffer = YES;
        mIsStarted = NO;
        mLayer = aLayer;
        
        NSString* bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
        FileSystem::setResourcePath([bundlePath fileSystemRepresentation]);
    }];
}

- (void)setMainTextureWithPath:(char *)aPath
{
    [[SKQueueDispatcher sharedDispatcher] runAsynchronouslyOnGLRenderingQueue:^{
        mMainTexturePath = aPath;
    }];
}

- (void)render
{
    [[SKQueueDispatcher sharedDispatcher] runAsynchronouslyOnGLRenderingQueue:^{
        if (mIsStarted && CustomRenderingEngine::getInstance()->getState() != Game::State::RUNNING)
        {
            return;
        }
        
        [EAGLContext setCurrentContext:mContext];
        
        if (mShouldUpdateFrameBuffer)
        {
            mShouldUpdateFrameBuffer = NO;
            
            CustomRenderingEngine::getInstance()->deleteFramebuffer();
            CustomRenderingEngine::getInstance()->createFrameAndColorRenderbuffer();
            
            [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:mLayer];
            
            CustomRenderingEngine::getInstance()->attachColorAndDepthBuffer();
        }
        
        if (!mShouldUpdateFrameBuffer && !mIsStarted)
        {
            mIsStarted = YES;
            
            CustomRenderingEngine::getInstance()->run();
            CustomRenderingEngine::getInstance()->initKuruScene();
            
            [self addMainTextureNode];
            
            return;
        }
        
        CustomRenderingEngine::getInstance()->bindFramebuffer();
        CustomRenderingEngine::getInstance()->applyViewport();
        CustomRenderingEngine::getInstance()->frame();
        CustomRenderingEngine::getInstance()->bindColorRenderbuffer();
        
        [mContext presentRenderbuffer:GL_RENDERBUFFER];
    }];
}


- (void)resumeEngine
{
    [[SKQueueDispatcher sharedDispatcher] runAsynchronouslyOnGLRenderingQueue:^{
        CustomRenderingEngine::getInstance()->resume();
    }];
}


- (void)pauseEngine
{
    [[SKQueueDispatcher sharedDispatcher] runAsynchronouslyOnGLRenderingQueue:^{
        CustomRenderingEngine::getInstance()->pause();
    }];
}


#pragma mark - privates

- (void)addMainTextureNode
{
    if (mMainTexturePath == NULL)
    {
        return;
    }
    
    Node *sNode = CustomRenderingEngine::getInstance()->addCameraFullScreenQuadModelAndNode();
    
    [self setTextureUnlitMaterial:dynamic_cast<Model*>(sNode->getDrawable()) texturePath:mMainTexturePath generateMipmaps:NO];
}

- (void)setTextureUnlitMaterial:(Model *)aModel texturePath:(char *)aTexturePath generateMipmaps:(BOOL)aMipmaps
{
    Material* sMaterial = aModel->setMaterial("res/shaders/textured.vert", "res/shaders/textured.frag");
    sMaterial->setParameterAutoBinding("u_worldViewProjectionMatrix", "WORLD_VIEW_PROJECTION_MATRIX");
    
    // Load the texture from file.
    Texture::Sampler* sampler = sMaterial->getParameter("u_diffuseTexture")->setValue(aTexturePath, aMipmaps);
    
    if (aMipmaps)
    {
        sampler->setFilterMode(Texture::LINEAR_MIPMAP_LINEAR, Texture::LINEAR);
    }
    else
    {
        sampler->setFilterMode(Texture::LINEAR, Texture::LINEAR);
        sampler->setWrapMode(Texture::CLAMP, Texture::CLAMP);
        sMaterial->getStateBlock()->setCullFace(true);
        sMaterial->getStateBlock()->setDepthTest(false);
        sMaterial->getStateBlock()->setDepthWrite(false);
    }
}

@end
