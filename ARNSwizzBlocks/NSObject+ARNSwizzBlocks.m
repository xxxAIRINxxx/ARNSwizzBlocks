//
//  NSObject+ARNSwizzBlocks.m
//  NSObject+ARNSwizzBlocks
//
//  Created by Airin on 2014/05/26.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "NSObject+ARNSwizzBlocks.h"
#import <objc/message.h>
#import <objc/runtime.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static NSString * const kARNSwizzSubclassPrefix = @"kARNSwizzSubclassPrefix";
static NSString * const kARNSwizzRespondForSelectorAliasPrefix = @"arn_swizzAlias_";

static void *ARNSWizzSubclassAssociationKey = &ARNSWizzSubclassAssociationKey;
static void *ARNSWizzOriginalClassAssociationKey = &ARNSWizzOriginalClassAssociationKey;

@implementation NSObject (ARNSwizzBlocks)

// It's hard to tell which struct return types use _objc_msgForward, and
// which use _objc_msgForward_stret instead, so just exclude all struct, array,
// union, complex and vector return types.
static void ARNSWizzCheckTypeEncoding(const char *typeEncoding) {
#if !NS_BLOCK_ASSERTIONS
	// Some types, including vector types, are not encoded. In these cases the
	// signature starts with the size of the argument frame.
	NSCAssert(*typeEncoding < '1' || *typeEncoding > '9', @"unknown method return type not supported in type encoding: %s", typeEncoding);
	NSCAssert(strstr(typeEncoding, "(") != typeEncoding, @"union method return type not supported");
	NSCAssert(strstr(typeEncoding, "{") != typeEncoding, @"struct method return type not supported");
	NSCAssert(strstr(typeEncoding, "[") != typeEncoding, @"array method return type not supported");
	NSCAssert(strstr(typeEncoding, @encode(_Complex float)) != typeEncoding, @"complex float method return type not supported");
	NSCAssert(strstr(typeEncoding, @encode(_Complex double)) != typeEncoding, @"complex double method return type not supported");
	NSCAssert(strstr(typeEncoding, @encode(_Complex long double)) != typeEncoding, @"complex long double method return type not supported");
    
#endif // !NS_BLOCK_ASSERTIONS
}

static NSMutableSet *ARNSwizzClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzClasses = [[NSMutableSet alloc] init];
    });
    
    return swizzClasses;
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - Replace Methods

static SEL ARNSwizzAliasForSelector(SEL originalSelector) {
    NSString *selectorName = NSStringFromSelector(originalSelector);
    return NSSelectorFromString([kARNSwizzRespondForSelectorAliasPrefix stringByAppendingString:selectorName]);
}

static BOOL ARNSwizzAliasForwardInvocation(NSInvocation *invocation) {
    SEL aliasSelector = ARNSwizzAliasForSelector(invocation.selector);
    
    Class class = object_getClass(invocation.target);
    BOOL respondsToAlias = [class instancesRespondToSelector:aliasSelector];
    if (respondsToAlias) {
        invocation.selector = aliasSelector;
        [invocation invoke];
    }
    
    return respondsToAlias;
}

static void ARNSwizzReplaceForwardInvocation(Class class) {
    SEL forwardInvocationSEL = @selector(forwardInvocation:);
    Method forwardInvocationMethod = class_getInstanceMethod(class, forwardInvocationSEL);
    
    void (*originalForwardInvocation)(id, SEL, NSInvocation *) = NULL;
    if (forwardInvocationMethod != NULL) {
        originalForwardInvocation = (__typeof__(originalForwardInvocation))method_getImplementation(forwardInvocationMethod);
    }
    
    id newForwardInvocation = ^(id self, NSInvocation *invocation) {
        // Call ARNSwizz Block
        BOOL matched = ARNSwizzAliasForwardInvocation(invocation);
        if (matched) { return; }
        
        // Try Call Original ForwardInvocation
        if (originalForwardInvocation == NULL) {
            [self doesNotRecognizeSelector:invocation.selector];
        } else {
            originalForwardInvocation(self, forwardInvocationSEL, invocation);
        }
    };
    
    class_replaceMethod(class, forwardInvocationSEL, imp_implementationWithBlock(newForwardInvocation), "v@:@");
}

static void ARNSwizzReplaceRespondsToSelector(Class class) {
    SEL respondsToSelectorSEL = @selector(respondsToSelector:);
    
    Method respondsToSelectorMethod = class_getInstanceMethod(class, respondsToSelectorSEL);
    BOOL (* originalRespondsToSelector)(id, SEL, SEL) = (__typeof__(originalRespondsToSelector))method_getImplementation(respondsToSelectorMethod);
    
    id newRespondsToSelector = ^ BOOL (id self, SEL selector) {
        Method method = arn_swizzGetImmediateInstanceMethod(class, selector);
        if (method != NULL && method_getImplementation(method) == _objc_msgForward) {
            SEL aliasSelector = ARNSwizzAliasForSelector(selector);
            if (objc_getAssociatedObject(self, aliasSelector) != nil) {
                return YES;
            }
        }
        return originalRespondsToSelector(self, respondsToSelectorSEL, selector);
    };
    
    class_replaceMethod(class, respondsToSelectorSEL, imp_implementationWithBlock(newRespondsToSelector), method_getTypeEncoding(respondsToSelectorMethod));
}

static void ARNSwizzReplaceGetClass(Class class, Class statedClass) {
    SEL selector = @selector(class);
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    class_replaceMethod(class, selector, newIMP, method_getTypeEncoding(class_getInstanceMethod(class, selector)));
}

static void ARNSwizzReplaceMethodSignatureForSelector(Class class) {
    IMP newIMP = imp_implementationWithBlock(^(id self, SEL selector) {
        Class actualClass = object_getClass(self);
        Method method = class_getInstanceMethod(actualClass, selector);
        if (method == NULL) {
            struct objc_super target = {
                .super_class = class_getSuperclass(class),
                .receiver = self,
            };
            NSMethodSignature * (* messageSned)(struct objc_super *, SEL, SEL) = (__typeof__(messageSned))objc_msgSendSuper;
            return messageSned(&target, @selector(methodSignatureForSelector:), selector);
        }
        
        return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    });
    
    SEL selector = @selector(methodSignatureForSelector:);
    Method methodSignatureForSelectorMethod = class_getInstanceMethod(class, selector);
    class_replaceMethod(class, selector, newIMP, method_getTypeEncoding(methodSignatureForSelectorMethod));
}

Method arn_swizzGetImmediateInstanceMethod(Class aClass, SEL aSelector) {
    unsigned methodCount = 0;
    Method *methods = class_copyMethodList(aClass, &methodCount);
    Method foundMethod = NULL;
    
    for (unsigned methodIndex = 0; methodIndex < methodCount; ++methodIndex) {
        if (method_getName(methods[methodIndex]) == aSelector) {
            foundMethod = methods[methodIndex];
            break;
        }
    }
    free(methods);
    return foundMethod;
}

static Class ARNSiwzzSwizzleClass(NSObject *self) {
    Class statedClass = self.class;
    Class baseClass = object_getClass(self);
    
    Class knownDynamicSubClass = objc_getAssociatedObject(self, ARNSWizzSubclassAssociationKey);
    if (knownDynamicSubClass != Nil) { return knownDynamicSubClass; }
    
    NSString *className = NSStringFromClass(baseClass);
    
    if (statedClass != baseClass) {
        @synchronized(ARNSwizzClasses()) {
            if (![ARNSwizzClasses() containsObject:className]) {
                ARNSwizzReplaceForwardInvocation(baseClass);
                ARNSwizzReplaceRespondsToSelector(baseClass);
                ARNSwizzReplaceGetClass(baseClass, statedClass);
                ARNSwizzReplaceGetClass(object_getClass(baseClass), statedClass);
                ARNSwizzReplaceMethodSignatureForSelector(baseClass);
                [ARNSwizzClasses() addObject:className];
            }
        }
        return baseClass;
    }
    
    const char *subClassName = [kARNSwizzSubclassPrefix stringByAppendingString:className].UTF8String;
    Class subclass = objc_getClass(subClassName);
    
    if (!subclass) {
        subclass = objc_allocateClassPair(baseClass, subClassName, 0);
        if (!subclass) { return nil; }
        
        ARNSwizzReplaceForwardInvocation(subclass);
        ARNSwizzReplaceRespondsToSelector(subclass);
        ARNSwizzReplaceGetClass(subclass, statedClass);
        ARNSwizzReplaceGetClass(object_getClass(subclass), statedClass);
        ARNSwizzReplaceMethodSignatureForSelector(subclass);
        ARNSiwzzDealloc(subclass);
        
        objc_registerClassPair(subclass);
    }
    
    object_setClass(self, subclass);
    objc_setAssociatedObject(self, ARNSWizzSubclassAssociationKey, subclass, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, ARNSWizzOriginalClassAssociationKey, statedClass, OBJC_ASSOCIATION_ASSIGN);
    
    return subclass;
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - Deallocating

static void ARNSiwzzDealloc(Class classToSwizzle) {
    @synchronized(ARNSwizzClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([ARNSwizzClasses() containsObject:className]) { return; }
        
        SEL deallocSelector = sel_registerName("dealloc");
        
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        
        id newDealloc = ^(__unsafe_unretained id self) {
            Class subclass = objc_getAssociatedObject(self, ARNSWizzSubclassAssociationKey);
            
            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(classToSwizzle)
                };
                
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
            
            if (subclass != NULL) {
                if ([className hasPrefix:kARNSwizzSubclassPrefix]) {
                    Class kvoClass = NSClassFromString([NSString stringWithFormat:@"NSKVONotifying_%@", className]);
                    if (kvoClass) {
                        objc_disposeClassPair(kvoClass);
                    }
                    objc_disposeClassPair(subclass);
                }
            }
        };
        
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
    }
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - ARNSwizzBlocks

- (void)arn_swizzRemoveBlockForSelector:(SEL)selector
{
    if (!selector) { return; }
    
    @synchronized(self) {
        Class dynamicSubClass = objc_getAssociatedObject(self, ARNSWizzSubclassAssociationKey);
        if (dynamicSubClass == Nil) { return; }
        
        Method targetMethod = class_getInstanceMethod(dynamicSubClass, selector);
        if (targetMethod != NULL && method_getImplementation(targetMethod) == _objc_msgForward) {
            Class originalClass = objc_getAssociatedObject(self, ARNSWizzOriginalClassAssociationKey);
            if (originalClass == Nil) { return; }
            
            Method originalMethod = class_getInstanceMethod(originalClass, selector);
            IMP originalIMP = method_getImplementation(originalMethod);
            
            class_replaceMethod(dynamicSubClass, selector, originalIMP, method_getTypeEncoding(originalMethod));
        }
    }
}

- (void)arn_swizzRespondsToSelector:(SEL)selector fromProtocol:(Protocol *)protocol usingBlock:(id)block
{
    if (!selector || !block) { return; }
    
    @synchronized(self) {
        Class dynamicSubclass = ARNSiwzzSwizzleClass(self);
        NSCAssert(dynamicSubclass != nil, @"Could not swizzle class of %@", self);
        
        Method targetMethod = class_getInstanceMethod(dynamicSubclass, selector);
        SEL aliasSelector = ARNSwizzAliasForSelector(selector);
        IMP swizzIMP = imp_implementationWithBlock(block);
        
        if (targetMethod == NULL) {
            const char *typeEncoding;
            if (!protocol || protocol == NULL) {
                const char *name = sel_getName(selector);
                NSMutableString *sigunature = [NSMutableString stringWithString:@"v@:"];
                while ((name = strchr(name,':')) != NULL) {
                    [sigunature appendString:@"@"];
                    name++;
                }
                typeEncoding = sigunature.UTF8String;
            } else {
                // optional instance method
                struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
                
                if (methodDescription.name == NULL) {
                    // required instance method
                    methodDescription = protocol_getMethodDescription(protocol, selector, YES, YES);
                    NSCAssert(methodDescription.name != NULL, @"Selector %@ does not exist in <%s>", NSStringFromSelector(selector), protocol_getName(protocol));
                }
                typeEncoding = methodDescription.types;
            }
            
            ARNSWizzCheckTypeEncoding(typeEncoding);
            
            BOOL addedAlias __attribute__((unused)) = class_addMethod(dynamicSubclass, aliasSelector, swizzIMP, typeEncoding);
            NSCAssert(addedAlias, @"Swizz implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), dynamicSubclass);
            
            BOOL addedOriginal __attribute__((unused)) = class_addMethod(dynamicSubclass, selector, _objc_msgForward, typeEncoding);
            NSCAssert(addedOriginal, @"can not add Method %@ on %@", NSStringFromSelector(selector), dynamicSubclass);
        } else {
            const char *typeEncoding = method_getTypeEncoding(targetMethod);
            
            ARNSWizzCheckTypeEncoding(typeEncoding);
            
            if (aliasSelector) {
                class_replaceMethod(dynamicSubclass, aliasSelector, swizzIMP, typeEncoding);
            } else {
                BOOL addedAlias __attribute__((unused)) = class_addMethod(dynamicSubclass, aliasSelector, swizzIMP, typeEncoding);
                NSCAssert(addedAlias, @"Swizz implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), dynamicSubclass);
            }
            
            class_replaceMethod(dynamicSubclass, selector, _objc_msgForward, typeEncoding);
        }
    }
}

@end
