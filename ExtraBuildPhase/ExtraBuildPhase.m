//
//  ExtraBuildPhase.m
//  ExtraBuildPhase
//
//  Created by 野村 憲男 on 11/7/15.
//
//  Copyright (c) 2015 Norio Nomura
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

@implementation NSObject (ExtraBuildPhase)

static bool _ExtraBuildPhase_in_createDependencyGraphSnapshot = false;

typedef id<PBXShellScriptBuildPhase> BuildPhase;

- (NSArray*)_ExtraBuildPhase_buildPhases
{
    NSArray *result = [self _ExtraBuildPhase_buildPhases];
    
    if (_ExtraBuildPhase_in_createDependencyGraphSnapshot) {
        NSString *identifier = [[NSBundle bundleForClass: [ExtraBuildPhase class]]bundleIdentifier];
        
        NSUserDefaults *defaults = [[NSUserDefaults alloc]initWithSuiteName: identifier];
        NSString *shellScript = [defaults stringForKey:@"shellScript"];
        if (!shellScript) {
            shellScript = @"if which swiftlint >/dev/null; then\n"
            "    swiftlint 2>/dev/null\n"
            "fi\n"
            "exit 0 # ignore result of swiftlint";
        }
        BOOL showEnvVarsInLog = [defaults boolForKey: @"showEnvVarsInLog"];
        
        Class buildPhaseClass = objc_getClass("PBXShellScriptBuildPhase");
        BuildPhase buildPhase = [(BuildPhase)[buildPhaseClass alloc] initWithName: @"Run SwiftLint"];
        [buildPhase setShowEnvVarsInLog: showEnvVarsInLog];
        [buildPhase setShellPath: @"/bin/sh"];
        [buildPhase setShellScript: shellScript];
        NSMutableArray *newResult = [result mutableCopy];
        [newResult addObject:buildPhase];
        return newResult;
    }

    return result;
}

- (id)_ExtraBuildPhase_createDependencyGraphSnapshotWithTargetBuildParameters: (id)arg
{
    _ExtraBuildPhase_in_createDependencyGraphSnapshot = true;
    id result = [self _ExtraBuildPhase_createDependencyGraphSnapshotWithTargetBuildParameters: arg];
    _ExtraBuildPhase_in_createDependencyGraphSnapshot = false;
    return result;
}

@end

@implementation ExtraBuildPhase

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    Class from = objc_getClass("PBXTarget");
    Class to = objc_getClass("NSObject");
    SEL fromSEL, toSEL;
    fromSEL = @selector(buildPhases);
    toSEL = @selector(_ExtraBuildPhase_buildPhases);
    method_exchangeImplementations(class_getInstanceMethod(from, fromSEL), class_getInstanceMethod(to, toSEL));
    fromSEL = @selector(createDependencyGraphSnapshotWithTargetBuildParameters:);
    toSEL = @selector(_ExtraBuildPhase_createDependencyGraphSnapshotWithTargetBuildParameters:);
    method_exchangeImplementations(class_getInstanceMethod(from, fromSEL), class_getInstanceMethod(to, toSEL));
}

@end
