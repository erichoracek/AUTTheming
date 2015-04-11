//
//  GBSettings+ThemingSymbolsGenerator.m
//  MTFThemingSymbolsGenerator
//
//  Created by Eric Horacek on 12/28/14.
//  Copyright (c) 2014 Eric Horacek. All rights reserved.
//

#import "GBSettings+ThemingSymbolsGenerator.h"

NSString * const MTFSettingsOptionThemes = @"theme";
NSString * const MTFSettingsOptionPrefix = @"prefix";
NSString * const MTFSettingsOptionOutput = @"output";
NSString * const MTFSettingsOptionTabs = @"tabs";
NSString * const MTFSettingsOptionIndentationCount = @"indentation-count";
NSString * const MTFSettingsOptionHelp = @"help";
NSString * const MTFSettingsOptionVerbose = @"verbose";
NSString * const MTFSettingsOptionModification = @"keep";

@implementation GBSettings (MTFThemingSymbolsGenerator)

+ (instancetype)mtf_settingsWithName:(NSString *)name parent:(GBSettings *)parent {
    id result = [self settingsWithName:name parent:parent];
    if (result) {
        [result registerArrayForKey:MTFSettingsOptionThemes];
    }
    return result;
}

- (void)mtf_applyDefaults {
    self.mtf_output = @"./";
    self.mtf_prefix = @"";
    self.mtf_shouldIndentUsingTabs = NO;
    self.mtf_indentationCount = 4;
    self.mtf_checkForModification = NO;
}

GB_SYNTHESIZE_OBJECT(NSArray *, mtf_themes, mtf_setThemes, MTFSettingsOptionThemes)
GB_SYNTHESIZE_OBJECT(NSString *, mtf_prefix, mtf_setPrefix, MTFSettingsOptionPrefix)
GB_SYNTHESIZE_OBJECT(NSString *, mtf_output, mtf_setOutput, MTFSettingsOptionOutput)
GB_SYNTHESIZE_BOOL(mtf_shouldIndentUsingTabs, mtf_setShouldIndentUsingTabs, MTFSettingsOptionTabs)
GB_SYNTHESIZE_INT(mtf_indentationCount, mtf_setIndentationCount, MTFSettingsOptionIndentationCount)
GB_SYNTHESIZE_BOOL(mtf_help, mtf_setHelp, MTFSettingsOptionHelp)
GB_SYNTHESIZE_BOOL(mtf_verbose, mtf_setVerbose, MTFSettingsOptionVerbose)
GB_SYNTHESIZE_BOOL(mtf_checkForModification, mtf_setCheckForModification, MTFSettingsOptionModification)

#pragma mark - Derived Properties

- (NSString *)mtf_indentationCharacter {
    return (self.mtf_shouldIndentUsingTabs ? @"\t" : @" ");
}

- (NSString *)mtf_indentation {
    NSMutableString *indentationString = [NSMutableString new];
    for (NSInteger _ = 0; _ < self.mtf_indentationCount; _++) {
        [indentationString appendString:self.mtf_indentationCharacter];
    }
    return [indentationString copy];
}

@end
