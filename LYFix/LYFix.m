//
//  LYFix.m
//  LYFix
//
//  Created by xly on 2018/7/25.
//  Copyright © 2018年 Xly. All rights reserved.
//

#import "LYFix.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIGeometry.h>
#import "Aspects.h"
#import "NSInvocation+LYAddtion.h"

@implementation LYFix

+ (JSContext *)context {
    static JSContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[JSContext alloc] init];
    });
    return context;
}

+ (void)Fix {
    JSContext *context = [self context];
    context[@"fixMethod"] = ^(NSString *className, NSString *selectorName, AspectOptions options, JSValue *fixImp) {
        [self fixWithClassName:className opthios:options selector:selectorName fixImp:fixImp];
    };
    context[@"runMethod"] = ^id(NSString * className, NSString *selectorName, NSArray *arguments) {
        return [self runWithClassname:className selector:selectorName arguments:arguments];
    };
    context[@"runInstanceMethod"] = ^id(JSValue *instance, NSString *selectorName, NSArray *arguments) {
        NSLog(@"xly--%@",@"^^^^^");
      
        return [self runWithInstance:instance selector:selectorName arguments:arguments];
    };
    context[@"runInvocation"] = ^(NSInvocation *invocation) {
        [invocation invoke];
    };

    [self context][@"setInvocationArguments"] = ^(NSInvocation *invocation, NSArray *arguments) {
        invocation.arguments = arguments;
    };
    [self context][@"setInvocationArgumentAtIndex"] = ^(NSInvocation *invocation, id argument,NSInteger index) {
        [invocation setMyArgument:argument atIndex:index];
    };
    [self context][@"setInvocationReturnValue"] = ^(NSInvocation *invocation, JSValue *returnValue) {
        invocation.returnValue_obj = returnValue.toObject;
    };
    context[@"runError"] = ^(NSString *instanceName, NSString *selectorName) {
        NSLog(@"runError: instanceName = %@, selectorName = %@", instanceName, selectorName);
    };
}

+ (id)evalString:(NSString *)jsString {
    if (jsString == nil || jsString == (id)[NSNull null] || ![jsString isKindOfClass:[NSString class]]) return nil;
    JSValue *jsValue = [[self context] evaluateScript:jsString];
    id obj = jsValue.toObject;
    if (obj) {
        return obj;
    } else {
        return nil;
    }
}

+ (void)fixWithClassName:(NSString *)className opthios:(AspectOptions)options selector:(NSString *)selector fixImp:(JSValue *)fixImp {
    Class cla = NSClassFromString(className);
    SEL sel = NSSelectorFromString(selector);
    if ([cla instancesRespondToSelector:sel]) {
        
    } else if ([cla respondsToSelector:sel]){
        cla = object_getClass(cla);
    } else {
        return;
    }
    [cla aspect_hookSelector:sel withOptions:options usingBlock:^(id<AspectInfo> aspectInfo) {
        [fixImp callWithArguments:@[aspectInfo.instance, aspectInfo.originalInvocation, aspectInfo.arguments]];
    } error:nil];
}

+ (id)runWithInstance:(id)instance selector:(NSString *)selector arguments:(NSArray *)arguments {
    if (!instance) {
        return nil;
    }
    SEL sel = NSSelectorFromString(selector);

    NSLog(@"xly--%@",[instance class]);
    if ([instance isKindOfClass:JSValue.class]) {
        instance = [instance toObject];
    }
    NSMethodSignature *signature = [instance methodSignatureForSelector:sel];
    if (!signature) {
        return nil;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = sel;
    invocation.arguments = arguments;
    [invocation invokeWithTarget:instance];
    return invocation.returnValue_obj;
}

+ (id)runWithClassname:(NSString *)className selector:(NSString *)selector arguments:(NSArray *)arguments {
    Class cla = NSClassFromString(className);
    SEL sel = NSSelectorFromString(selector);
    if ([cla instancesRespondToSelector:sel]) {
        id instance = [[cla alloc] init];
        NSMethodSignature *signature = [instance methodSignatureForSelector:sel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = sel;
        invocation.arguments = arguments;
        [invocation invokeWithTarget:instance];
        return invocation.returnValue_obj;
    } else if ([cla respondsToSelector:sel]){
        NSMethodSignature *signature = [cla methodSignatureForSelector:sel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = sel;
        invocation.arguments = arguments;
        [invocation invokeWithTarget:cla];
        return invocation.returnValue_obj;
    } else {
        return nil;
    }
}

@end
