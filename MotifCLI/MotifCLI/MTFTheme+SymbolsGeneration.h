//
//  MTFTheme+SymbolsGeneration.h
//  MTFThemingSymbolsGenerator
//
//  Created by Eric Horacek on 12/28/14.
//  Copyright (c) 2014 Eric Horacek. All rights reserved.
//

#import <Motif/Motif.h>

@interface MTFTheme (SymbolsGeneration)

- (void)generateSymbolsFilesInDirectory:(NSURL *)directoryURL indentation:(NSString *)indentation prefix:(NSString *)prefix checkForModification:(BOOL)checkForModification;

+ (void)generateSymbolsUmbrellaHeaderFromThemes:(NSArray *)themes inDirectory:(NSURL *)directoryURL prefix:(NSString *)prefix checkForModification:(BOOL)checkForModification;

@property (nonatomic, readonly) NSArray *constantKeys;
@property (nonatomic, readonly) NSArray *classNames;
@property (nonatomic, readonly) NSArray *properties;

@end
