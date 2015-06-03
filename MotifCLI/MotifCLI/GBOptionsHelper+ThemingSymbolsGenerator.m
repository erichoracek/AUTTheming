//
//  GBOptionsHelper+ThemingSymbolsGenerator.m
//  MTFThemingSymbolsGenerator
//
//  Created by Eric Horacek on 12/28/14.
//  Copyright (c) 2014 Eric Horacek. All rights reserved.
//

#import "GBOptionsHelper+ThemingSymbolsGenerator.h"
#import "GBSettings+ThemingSymbolsGenerator.h"

@implementation GBOptionsHelper (ThemingSymbolsGenerator)

- (void)mtf_registerOptions {
    [self registerOption:'t'
        long:MTFSettingsOptionThemes
        description:@"The YAML or JSON theme file(s) to generate symbols from. "
            "You may specify more than one theme by using this parameter more "
            "than once (e.g. -t theme1.json -t theme2.yaml)."
        flags:GBOptionRequiredValue];

    [self registerOption:'o'
        long:MTFSettingsOptionOutput
        description:@"The symbol files output path. Defaults to the current "
            "working directory."
        flags:GBOptionRequiredValue];

    [self registerOption:'p'
        long:MTFSettingsOptionPrefix
        description:@"The prefix for the symbols generated by this tool. "
            "Defaults to 'MTF'."
        flags:GBOptionOptionalValue];

    [self registerOption:'a'
        long:MTFSettingsOptionTabs
        description:@"Indent the generated symbol files using tabs, rather "
            "than spaces (the default)."
        flags:GBOptionNoValue];

    [self registerOption:'i'
        long:MTFSettingsOptionIndentationCount
        description:@"The number of characters that should be used to indent "
            "struct members in the symbols files. Defaults to 4."
        flags:GBOptionNoValue];

    [self registerOption:'h'
        long:MTFSettingsOptionHelp
        description:@"Display this help message and exit."
        flags:GBOptionNoValue];

    [self registerOption:'v'
        long:MTFSettingsOptionVerbose
        description:@"Print output verbosely when executing."
        flags:GBOptionNoValue];
}

@end
