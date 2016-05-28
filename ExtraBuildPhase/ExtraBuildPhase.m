//
//  ExtraBuildPhase.m
//  ExtraBuildPhase
//
//  Created by 野村 憲男 on 11/7/15.
//
//  Copyright (c) 2016 Norio Nomura
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>
#import "ExtraBuildPhase.h"
#import "PBXShellScriptBuildPhase.h"
#import "PBXTarget.h"

@implementation ExtraBuildPhase(SwizzlingTargetMethods)

static bool _ExtraBuildPhase_in_createDependencyGraphSnapshot = false;

typedef id<PBXShellScriptBuildPhase> BuildPhase;

/// replacement for -[PBXTarget buildPhases];
- (NSArray<id<PBXBuildPhase>>*)_ExtraBuildPhase_buildPhases
{
    // call original method
    NSArray<id<PBXBuildPhase>> *result = [self _ExtraBuildPhase_buildPhases];
    
    if (!_ExtraBuildPhase_in_createDependencyGraphSnapshot) {
        return result;
    }
    
    NSString *identifier = [[NSBundle bundleForClass:[ExtraBuildPhase class]]bundleIdentifier];
    NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName:identifier];
    
    NSString *processName = [[NSProcessInfo processInfo]processName];
    if (![processName isEqual:@"Xcode"] && ![defaults boolForKey:@"isNotLimitedToXcode"]) {
        return result;
    }
    
    NSString *shellScript = [defaults stringForKey:@"shellScript"];
    if (!shellScript) {
        shellScript = @"if which swiftlint >/dev/null; then\n"
        "    [ -f .swiftlint.yml ] && CONFIG=\".swiftlint.yml\" || CONFIG=\"$HOME/.swiftlint.yml\"\n"
        "    swiftlint lint --quiet --use-script-input-files --config $CONFIG\n"
        "fi\n"
        "exit 0 # ignore result of swiftlint";
    }
    BOOL showEnvVarsInLog = [defaults boolForKey:@"showEnvVarsInLog"];
    BOOL shellScriptRunsSwiftLint = [shellScript containsString:@"if which swiftlint"];

    Class shellScriptBuildPhaseClass = objc_getClass("PBXShellScriptBuildPhase");
    BuildPhase extraBuildPhase = [(BuildPhase)[shellScriptBuildPhaseClass alloc] initWithName:@"Run SwiftLint"];
    [extraBuildPhase setShowEnvVarsInLog:showEnvVarsInLog];
    [extraBuildPhase setShellPath:@"/bin/sh"];
    [extraBuildPhase setShellScript:shellScript];

    Class SourcesBuildPhaseClass = objc_getClass("PBXSourcesBuildPhase");
    NSMutableArray<NSString *> *inputPaths = [[NSMutableArray<NSString *> alloc]init];
    for (id<PBXBuildPhase> buildPhase in result) {
        if ([buildPhase isKindOfClass:SourcesBuildPhaseClass]) {
            for (id<PBXBuildFile> buildFile in [buildPhase buildFiles]) {
                NSString *path = [[buildFile fileReference]projectRelativePath];
                if (path) {
                    [inputPaths addObject:[@"$(SRCROOT)/" stringByAppendingString:path]];
                }
            }
        } else if (shellScriptRunsSwiftLint && [buildPhase isKindOfClass:shellScriptBuildPhaseClass]) {
            BuildPhase anotherShellScriptBuildPhase = (BuildPhase)buildPhase;
            NSString *shellScript = [anotherShellScriptBuildPhase shellScript];
            if ([shellScript containsString:@"if which swiftlint"]) {
                return result;
            }
        }
    }
    
    if ([inputPaths count]) {
        [extraBuildPhase setInputPaths:inputPaths];
    }
    
    NSMutableArray *newResult = [result mutableCopy];
    [newResult addObject:extraBuildPhase];
    return newResult;
}

/// replacement for -[PBXTarget createDependencyGraphSnapshotWithTargetBuildParameters:];
- (id)_ExtraBuildPhase_createDependencyGraphSnapshotWithTargetBuildParameters:(id)arg
{
    _ExtraBuildPhase_in_createDependencyGraphSnapshot = true;
    
    // call original method
    id result = [self _ExtraBuildPhase_createDependencyGraphSnapshotWithTargetBuildParameters:arg];
    
    _ExtraBuildPhase_in_createDependencyGraphSnapshot = false;
    return result;
}

@end

@implementation ExtraBuildPhase

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    // When multiple instances of plugin are loaded, multiple call of this method may happen.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class target = objc_getClass("PBXTarget");
        
        SEL mySelector1 = @selector(_ExtraBuildPhase_buildPhases);
        SEL mySelector2 = @selector(_ExtraBuildPhase_createDependencyGraphSnapshotWithTargetBuildParameters:);
        
        SEL targetSelector1 = @selector(buildPhases);
        SEL targetSelector2 = @selector(createDependencyGraphSnapshotWithTargetBuildParameters:);
        
        if ([self addMyInstanceMethodBySelector:mySelector1 toClass:target] &&
            [self addMyInstanceMethodBySelector:mySelector2 toClass:target]) {
            [self exchangeMethodImplementationsBetweenSelector:mySelector1
                                                   andSelector:targetSelector1
                                                       ofClass:target];
            [self exchangeMethodImplementationsBetweenSelector:mySelector2
                                                   andSelector:targetSelector2
                                                       ofClass:target];
        }
    });
}

+ (BOOL)addMyInstanceMethodBySelector:(SEL)aSelector toClass:(Class)aClass
{
    // check existence before adding
    Method method = class_getInstanceMethod(aClass, aSelector);
    if (method) {
        NSLog(@"#ExtraBuildPhase: target method is already added. Are multiple ExtraBuildPhase.xcplugin installed?");
        return NO;
    }
    
    Method myMethod = class_getInstanceMethod([self class], aSelector);
    IMP imp = method_getImplementation(myMethod);
    const char *types = method_getTypeEncoding(myMethod);
    return class_addMethod(aClass, aSelector, imp, types);
}

+ (void)exchangeMethodImplementationsBetweenSelector:(SEL)selector1
                                         andSelector:(SEL)selector2
                                             ofClass:(Class)aClass
{
    Method method1 = class_getInstanceMethod(aClass, selector1);
    Method method2 = class_getInstanceMethod(aClass, selector2);
    method_exchangeImplementations(method1, method2);
}

@end
