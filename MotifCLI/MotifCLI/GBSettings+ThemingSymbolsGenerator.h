//
//  GBSettings+ThemingSymbolsGenerator.h
//  MTFThemingSymbolsGenerator
//
//  Created by Eric Horacek on 12/28/14.
//  Copyright (c) 2014 Eric Horacek. All rights reserved.
//

#import <GBCli/GBCli.h>

extern NSString * const MTFSettingsOptionThemes;
extern NSString * const MTFSettingsOptionPrefix;
extern NSString * const MTFSettingsOptionOutput;
extern NSString * const MTFSettingsOptionTabs;
extern NSString * const MTFSettingsOptionIndentationCount;
extern NSString * const MTFSettingsOptionHelp;
extern NSString * const MTFSettingsOptionVerbose;
extern NSString * const MTFSettingsOptionModification;

@interface GBSettings (ThemingSymbolsGenerator)

+ (instancetype)mtf_settingsWithName:(NSString *)name parent:(GBSettings *)parent;

- (void)mtf_applyDefaults;

@property (nonatomic, setter=mtf_setThemes:) NSArray *mtf_themes;

@property (nonatomic, setter=mtf_setPrefix:) NSString *mtf_prefix;

@property (nonatomic, setter=mtf_setOutput:) NSString *mtf_output;

@property (nonatomic, setter=mtf_setShouldIndentUsingTabs:) BOOL mtf_shouldIndentUsingTabs;

@property (nonatomic, setter=mtf_setIndentationCount:) NSInteger mtf_indentationCount;

@property (nonatomic, setter=mtf_setHelp:) BOOL mtf_help;

@property (nonatomic, setter=mtf_setVerbose:) BOOL mtf_verbose;

@property (nonatomic, setter=mtf_setCheckForModification:) BOOL mtf_checkForModification;

#pragma mark - Derived Properties

- (NSString *)mtf_indentation;

@end
