//
//  MTFThemingSymbolsGenerator.m
//  MTFThemingSymbolsGenerator
//
//  Created by Eric Horacek on 12/28/14.
//  Copyright (c) 2014 Eric Horacek. All rights reserved.
//

#import <GBCli/GBCli.h>
#import <Motif/Motif.h>
#import "MTFThemingSymbolsGenerator.h"
#import "GBSettings+ThemingSymbolsGenerator.h"
#import "GBOptionsHelper+ThemingSymbolsGenerator.h"
#import "MTFTheme+SymbolsGeneration.h"
#import "NSURL+CLIHelpers.h"

@implementation MTFThemingSymbolsGenerator

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (int)runWithSettings:(GBSettings *)settings; {
    // Do not resolve references when parsing themes
    [MTFThemeParser setShouldResolveReferences:NO];
    
    // Build an array of `MTFThemes` from the passed `theme` path params
    NSMutableArray *themes = [NSMutableArray new];
    for (NSString *themePath in settings.mtf_themes) {
        NSURL *themeURL = [NSURL mtf_fileURLFromPathParameter:themePath];
        if (!themeURL) {
            gbfprintln(stderr, @"[!] Error: '%@' is an invalid file path. Please supply another.", themePath);
            return 1;
        }
        NSError *error;
        MTFTheme *theme = [[MTFTheme alloc]
            initWithJSONFile:themeURL
            error:&error];
        if (error) {
            gbfprintln(stderr, @"[!] Error: Unable to parse theme at URL '%@': %@", themeURL, error);
            return 1;
        }
        [themes addObject:theme];
    }
    
    // Ensure the output param is a valid path
    NSString *outputPath = settings.mtf_output;
    NSURL *outputDirectoryURL = [NSURL
        mtf_directoryURLFromPathParameter:outputPath];
    
    if (!outputDirectoryURL) {
        gbfprintln(stderr, @"[!] Error: '%@' is an invalid directory path. Please supply another.", outputPath);
        return 1;
    }
    
    // Generate the symbols files for each theme
    for (MTFTheme *theme in themes) {
        [theme
            generateSymbolsFilesInDirectory:outputDirectoryURL
            indentation:settings.mtf_indentation
            prefix:settings.mtf_prefix
            checkForModification:settings.mtf_checkForModification];
    }
    
    // If there is more than one theme, generate an umbrella header to enable
    // consumers to import all symbols files at once
    if (themes.count > 1) {
        [MTFTheme
            generateSymbolsUmbrellaHeaderFromThemes:themes
            inDirectory:outputDirectoryURL
            prefix:settings.mtf_prefix
            checkForModification:settings.mtf_checkForModification];
    }
    
    return 0;
}

@end

int MTFThemingSymbolsGeneratorMain(int argc, const char *argv[]) {
    int result = 0;
    @autoreleasepool {
        
        GBSettings *defaultSettings = [GBSettings
            mtf_settingsWithName:@"defaults"
            parent:nil];
        
        GBSettings *settings = [GBSettings
            mtf_settingsWithName:@"arguments"
            parent:defaultSettings];
        
        [defaultSettings mtf_applyDefaults];
        
        GBOptionsHelper *options = [GBOptionsHelper new];
        [options mtf_registerOptions];
        
        GBCommandLineParser *parser = [GBCommandLineParser new];
        [parser registerSettings:settings];
        [parser registerOptions:options];
        [parser parseOptionsWithArguments:(char **)argv count:argc];
        
        // If there are either no args supplied or the help arg is supplied,
        // display help and exit
        if (argc == 1 || settings.mtf_help) {
            [options printHelp];
            return 0;
        }
        
        result = [MTFThemingSymbolsGenerator.sharedInstance
            runWithSettings:settings];
    }
    return result;
}
