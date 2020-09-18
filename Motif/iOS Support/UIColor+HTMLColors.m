//
//  UIColor+HTMLColors.m
//
//  Created by James Lawton on 12/9/12.
//  Copyright (c) 2012 James Lawton. All rights reserved.
//

#import "UIColor+HTMLColors.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    CGFloat a, b, c;
} MTFFloatTriple;

typedef struct {
    CGFloat a, b, c, d;
} MTFFloatQuad;

// CSS uses HSL, but we have to specify UIColor as HSB
static inline MTFFloatTriple HSB2HSL(CGFloat hue, CGFloat saturation, CGFloat brightness);
static inline MTFFloatTriple HSL2HSB(CGFloat hue, CGFloat saturation, CGFloat lightness);

static NSArray *MTFW3CColorNames(void);
static NSDictionary *MTFW3CNamedColors(void);


@implementation UIColor (HTMLColors)

#pragma mark - Reading

+ (nullable UIColor *)mtf_colorWithCSS:(NSString *)cssColor
{
    UIColor *color = nil;
    NSScanner *scanner = [NSScanner scannerWithString:cssColor];
    [scanner mtf_scanCSSColor:&color];
    return (scanner.isAtEnd) ? color : nil;
}

+ (nullable UIColor *)mtf_colorWithHexString:(NSString *)hexColor
{
    UIColor *color = nil;
    NSScanner *scanner = [NSScanner scannerWithString:hexColor];
    [scanner mtf_scanHexColor:&color];
    return (scanner.isAtEnd) ? color : nil;
}

+ (nullable UIColor *)mtf_colorWithRGBString:(NSString *)rgbColor
{
    UIColor *color = nil;
    NSScanner *scanner = [NSScanner scannerWithString:rgbColor];
    [scanner mtf_scanRGBColor:&color];
    return (scanner.isAtEnd) ? color : nil;
}

+ (nullable UIColor *)mtf_colorWithHSLString:(NSString *)hslColor
{
    UIColor *color = nil;
    NSScanner *scanner = [NSScanner scannerWithString:hslColor];
    [scanner mtf_scanHSLColor:&color];
    return (scanner.isAtEnd) ? color : nil;
}

+ (nullable UIColor *)mtf_colorWithW3CNamedColor:(NSString *)namedColor
{
    UIColor *color = nil;
    NSScanner *scanner = [NSScanner scannerWithString:namedColor];
    [scanner mtf_scanW3CNamedColor:&color];
    return (scanner.isAtEnd) ? color : nil;
}

#pragma mark - Writing

static inline unsigned ToByte(CGFloat f)
{
    f = MAX(0, MIN(f, 1)); // Clamp
    return (unsigned)round(f * 255);
}

- (nullable NSString *)mtf_hexStringValue
{
    NSString *hex = nil;
    CGFloat red, green, blue, alpha;
    if ([self mtf_getRed:&red green:&green blue:&blue alpha:&alpha]) {
        hex = [NSString stringWithFormat:@"#%02X%02X%02X",
               ToByte(red), ToByte(green), ToByte(blue)];
    }
    return hex;
}

- (nullable NSString *)mtf_rgbStringValue
{
    NSString *rgb = nil;
    CGFloat red, green, blue, alpha;
    if ([self mtf_getRed:&red green:&green blue:&blue alpha:&alpha]) {
        if (alpha == 1.0) {
            rgb = [NSString stringWithFormat:@"rgb(%u, %u, %u)",
                   ToByte(red), ToByte(green), ToByte(blue)];
        } else {
            rgb = [NSString stringWithFormat:@"rgba(%u, %u, %u, %g)",
                   ToByte(red), ToByte(green), ToByte(blue), alpha];
        }
    }
    return rgb;
}

static inline unsigned ToDeg(CGFloat f)
{
    return (unsigned)round(f * 360) % 360;
}

static inline unsigned ToPercentage(CGFloat f)
{
    f = MAX(0, MIN(f, 1)); // Clamp
    return (unsigned)round(f * 100);
}

- (nullable NSString *)mtf_hslStringValue
{
    NSString *hsl = nil;
    CGFloat hue, saturation, brightness, alpha;
    if ([self mtf_getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        MTFFloatTriple hslVal = HSB2HSL(hue, saturation, brightness);
        if (alpha == 1.0) {
            hsl = [NSString stringWithFormat:@"hsl(%u, %u%%, %u%%)",
                   ToDeg(hslVal.a), ToPercentage(hslVal.b), ToPercentage(hslVal.c)];
        } else {
            hsl = [NSString stringWithFormat:@"hsla(%u, %u%%, %u%%, %g)",
                   ToDeg(hslVal.a), ToPercentage(hslVal.b), ToPercentage(hslVal.c), alpha];
        }
    }
    return hsl;
}

// Fix up getting color components
- (BOOL)mtf_getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
    if ([self getRed:red green:green blue:blue alpha:alpha]) {
        return YES;
    }

    CGFloat white;
    if ([self getWhite:&white alpha:alpha]) {
        if (red)
            *red = white;
        if (green)
            *green = white;
        if (blue)
            *blue = white;
        return YES;
    }

    return NO;
}

- (BOOL)mtf_getHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness alpha:(CGFloat *)alpha
{
    if ([self getHue:hue saturation:saturation brightness:brightness alpha:alpha]) {
        return YES;
    }

    CGFloat white;
    if ([self getWhite:&white alpha:alpha]) {
        if (hue)
            *hue = 0;
        if (saturation)
            *saturation = 0;
        if (brightness)
            *brightness = white;
        return YES;
    }

    return NO;
}

+ (NSArray *)mtf_W3CColorNames
{
    return [[MTFW3CNamedColors() allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

@end


@implementation NSScanner (HTMLColors)

- (BOOL)mtf_scanCSSColor:(UIColor **)color
{
    return [self mtf_scanHexColor:color]
        || [self mtf_scanRGBColor:color]
        || [self mtf_scanHSLColor:color]
        || [self mtf_scanTransparent:color]
        || [self mtf_scanW3CNamedColor:color];
}

- (BOOL)mtf_scanRGBColor:(__autoreleasing UIColor **)color
{
    return [self mtf_caseInsensitiveWithCleanup:^BOOL{
        if ([self scanString:@"rgba" intoString:NULL]) {
            MTFFloatQuad scale = {1.0f/255.0f, 1.0f/255.0f, 1.0f/255.0f, 1.0f};
            MTFFloatQuad q;
            if ([self mtf_scanFloatQuad:&q scale:scale]) {
                if (color) {
                    *color = [UIColor colorWithRed:q.a green:q.b blue:q.c alpha:q.d];
                }
                return YES;
            }
        } else if ([self scanString:@"rgb" intoString:NULL]) {
            MTFFloatTriple scale = {1.0f/255.0f, 1.0f/255.0f, 1.0f/255.0f};
            MTFFloatTriple t;
            if ([self mtf_scanFloatTriple:&t scale:scale]) {
                if (color) {
                    *color = [UIColor colorWithRed:t.a green:t.b blue:t.c alpha:1.0];
                }
                return YES;
            }
        }
        return NO;
    }];
}

// Wrap hues in a circle, where [0,1] = [0°,360°]
static inline CGFloat MTFNormHue(CGFloat hue)
{
    return hue - floorf((float)hue);
}

- (BOOL)mtf_scanHSLColor:(__autoreleasing UIColor **)color
{
    return [self mtf_caseInsensitiveWithCleanup:^BOOL{
        if ([self scanString:@"hsla" intoString:NULL]) {
            MTFFloatQuad scale = {1.0f/360.0f, 1.0f, 1.0f, 1.0f};
            MTFFloatQuad q;
            if ([self mtf_scanFloatQuad:&q scale:scale]) {
                if (color) {
                    MTFFloatTriple t = HSL2HSB(MTFNormHue(q.a), q.b, q.c);
                    *color = [UIColor colorWithHue:t.a saturation:t.b brightness:t.c alpha:q.d];
                }
                return YES;
            }
        } else if ([self scanString:@"hsl" intoString:NULL]) {
            MTFFloatTriple scale = {1.0f/360.0f, 1.0f, 1.0f};
            MTFFloatTriple t;
            if ([self mtf_scanFloatTriple:&t scale:scale]) {
                if (color) {
                    t = HSL2HSB(MTFNormHue(t.a), t.b, t.c);
                    *color = [UIColor colorWithHue:t.a saturation:t.b brightness:t.c alpha:1.0];
                }
                return YES;
            }
        }
        return NO;
    }];
}

- (BOOL)mtf_scanHexColor:(__autoreleasing UIColor **)color
{
    return [self mtf_resetScanLocationOnFailure:^BOOL{
        return [self scanString:@"#" intoString:NULL]
            && [self mtf_scanHexTriple:color];
    }];
}

- (BOOL)mtf_scanW3CNamedColor:(__autoreleasing UIColor **)color
{
    return [self mtf_caseInsensitiveWithCleanup:^BOOL{
        NSArray *colorNames = MTFW3CColorNames();
        NSDictionary *namedColors = MTFW3CNamedColors();
        for (NSString *name in colorNames) {
            if ([self scanString:name intoString:NULL]) {
                if (color) {
                    *color = [UIColor mtf_colorWithHexString:namedColors[name]];
                }
                return YES;
            }
        }
        return NO;
    }];
}

#pragma mark - Private

- (void)mtf_withSkip:(NSCharacterSet *)chars run:(void (^)(void))block
{
    NSCharacterSet *skipped = self.charactersToBeSkipped;
    self.charactersToBeSkipped = chars;
    block();
    self.charactersToBeSkipped = skipped;
}

- (void)mtf_withNoSkip:(void (^)(void))block
{
    NSCharacterSet *skipped = self.charactersToBeSkipped;
    self.charactersToBeSkipped = nil;
    block();
    self.charactersToBeSkipped = skipped;
}

- (NSRange)mtf_rangeFromScanLocation
{
    NSUInteger loc = self.scanLocation;
    NSUInteger len = self.string.length - loc;
    return NSMakeRange(loc, len);
}

- (void)mtf_skipCharactersInSet:(NSCharacterSet *)chars
{
    [self mtf_withNoSkip:^{
        [self scanCharactersFromSet:chars intoString:NULL];
    }];
}

- (void)mtf_skip
{
    [self mtf_skipCharactersInSet:self.charactersToBeSkipped];
}

- (BOOL)mtf_resetScanLocationOnFailure:(BOOL (^)(void))block
{
    NSUInteger initialScanLocation = self.scanLocation;
    if (!block()) {
        self.scanLocation = initialScanLocation;
        return NO;
    }
    return YES;
}

- (BOOL)mtf_caseInsensitiveWithCleanup:(__attribute__((noescape)) BOOL (^)(void))block
{
    NSUInteger initialScanLocation = self.scanLocation;
    BOOL caseSensitive = self.caseSensitive;
    self.caseSensitive = NO;

    BOOL success = block();
    if (!success) {
        self.scanLocation = initialScanLocation;
    }

    self.caseSensitive = caseSensitive;
    return success;
}

// Scan, but only so far
- (NSRange)mtf_scanCharactersInSet:(NSCharacterSet *)chars maxLength:(NSUInteger)maxLength intoString:(NSString **)outString
{
    NSRange range = [self mtf_rangeFromScanLocation];
    range.length = MIN(range.length, maxLength);

    NSUInteger len;
    for (len = 0; len < range.length; ++len) {
        if (![chars characterIsMember:[self.string characterAtIndex:(range.location + len)]]) {
            break;
        }
    }

    NSRange charRange = NSMakeRange(range.location, len);
    if (outString) {
        *outString = [self.string substringWithRange:charRange];
    }

    self.scanLocation = charRange.location + charRange.length;

    return charRange;
}

// Hex characters
static NSCharacterSet *MTFHexCharacters() {
    static NSCharacterSet *hexChars;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hexChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"];
    });
    return hexChars;
}

// We know we've got hex already, so assume this works
static NSUInteger MTFParseHex(NSString *str, BOOL repeated)
{
    unsigned int ans = 0;
    if (repeated) {
        str = [NSString stringWithFormat:@"%@%@", str, str];
    }
    NSScanner *scanner = [NSScanner scannerWithString:str];
    [scanner scanHexInt:&ans];
    return ans;
}

// Scan FFF or FFFFFF, doesn't reset scan location on failure
- (BOOL)mtf_scanHexTriple:(UIColor **)color
{
    NSString *hex = nil;
    NSRange range = [self mtf_scanCharactersInSet:MTFHexCharacters() maxLength:6 intoString:&hex];
    CGFloat red, green, blue;
    if (hex.length == 6) {
        // Parse 2 chars per component
        red   = MTFParseHex([hex substringWithRange:NSMakeRange(0, 2)], NO) / 255.0f;
        green = MTFParseHex([hex substringWithRange:NSMakeRange(2, 2)], NO) / 255.0f;
        blue  = MTFParseHex([hex substringWithRange:NSMakeRange(4, 2)], NO) / 255.0f;
    } else if (hex.length >= 3) {
        // Parse 1 char per component, but repeat it to calculate hex value
        red   = MTFParseHex([hex substringWithRange:NSMakeRange(0, 1)], YES) / 255.0f;
        green = MTFParseHex([hex substringWithRange:NSMakeRange(1, 1)], YES) / 255.0f;
        blue  = MTFParseHex([hex substringWithRange:NSMakeRange(2, 1)], YES) / 255.0f;
        self.scanLocation = range.location + 3;
    } else {
        return NO; // Fail
    }
    if (color) {
        *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    }
    return YES;
}

// Scan "transparent"
- (BOOL)mtf_scanTransparent:(__autoreleasing UIColor **)color
{
    return [self mtf_caseInsensitiveWithCleanup:^BOOL{
        if ([self scanString:@"transparent" intoString:NULL]) {
            if (color) {
                *color = [UIColor colorWithWhite:0 alpha:0];
            }
            return YES;
        }
        return NO;
    }];
}

// Scan a float or percentage. Multiply float by `scale` if it was not a
// percentage.
- (BOOL)mtf_scanNum:(CGFloat *)value scale:(CGFloat)scale
{
    CGFloat f = 0.0;
    if ([self scanDouble:&f]) {
        if ([self scanString:@"%" intoString:NULL]) {
            f *= 0.01;
        } else {
            f *= scale;
        }
        if (value) {
            *value = f;
        }
        return YES;
    }
    return NO;
}

// Scan a triple of numbers "(10, 10, 10)". If they are not percentages, multiply
// by the corresponding `scale` component.
- (BOOL)mtf_scanFloatTriple:(MTFFloatTriple *)triple scale:(MTFFloatTriple)scale
{
    __block BOOL success = NO;
    __block MTFFloatTriple t;
    [self mtf_withSkip:[NSCharacterSet whitespaceAndNewlineCharacterSet] run:^{
        success = [self scanString:@"(" intoString:NULL]
            && [self mtf_scanNum:&(t.a) scale:scale.a]
            && [self scanString:@"," intoString:NULL]
            && [self mtf_scanNum:&(t.b) scale:scale.b]
            && [self scanString:@"," intoString:NULL]
            && [self mtf_scanNum:&(t.c) scale:scale.c]
            && [self scanString:@")" intoString:NULL];
    }];
    if (triple) {
        *triple = t;
    }
    return success;
}

// Scan a quad of numbers "(10, 10, 10, 10)". If they are not percentages,
// multiply by the corresponding `scale` component.
- (BOOL)mtf_scanFloatQuad:(MTFFloatQuad *)quad scale:(MTFFloatQuad)scale
{
    __block BOOL success = NO;
    __block MTFFloatQuad q;
    [self mtf_withSkip:[NSCharacterSet whitespaceAndNewlineCharacterSet] run:^{
        success = [self scanString:@"(" intoString:NULL]
            && [self mtf_scanNum:&(q.a) scale:scale.a]
            && [self scanString:@"," intoString:NULL]
            && [self mtf_scanNum:&(q.b) scale:scale.b]
            && [self scanString:@"," intoString:NULL]
            && [self mtf_scanNum:&(q.c) scale:scale.c]
            && [self scanString:@"," intoString:NULL]
            && [self mtf_scanNum:&(q.d) scale:scale.d]
            && [self scanString:@")" intoString:NULL];
    }];
    if (quad) {
        *quad = q;
    }
    return success;
}

@end

static inline MTFFloatTriple HSB2HSL(CGFloat hue, CGFloat saturation, CGFloat brightness)
{
    CGFloat l = (2.0f - saturation) * brightness;
    saturation *= brightness;
    CGFloat satDiv = (l <= 1.0f) ? l : (2.0f - l);
    if (satDiv != 0.0) {
        saturation /= satDiv;
    }
    l *= 0.5;
    MTFFloatTriple hsl = {
        hue,
        saturation,
        l
    };
    return hsl;
}

static inline MTFFloatTriple HSL2HSB(CGFloat hue, CGFloat saturation, CGFloat l)
{
    l *= 2.0f;
    CGFloat s = saturation * ((l <= 1.0f) ? l : (2.0f - l));
    CGFloat brightness = (l + s) * 0.5f;
    if (s != 0.0) {
        s = (2.0f * s) / (l + s);
    }
    MTFFloatTriple hsb = {
        hue,
        s,
        brightness
    };
    return hsb;
}

// Color names, longest first
static NSArray *MTFW3CColorNames() {
    static NSArray *colorNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorNames = [[MTFW3CNamedColors() allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *k1, NSString *k2) {
            NSInteger diff = k1.length - k2.length;
            if (!diff) {
                return NSOrderedSame;
            } else if (diff > 0) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }];
    });
    return colorNames;
}

// Color values as defined in CSS3 spec.
// See: http://www.w3.org/TR/css3-color/#svg-color
static NSDictionary *MTFW3CNamedColors() {
    static NSDictionary *namedColors;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        namedColors = @{
            @"AliceBlue" : @"#F0F8FF",
            @"AntiqueWhite" : @"#FAEBD7",
            @"Aqua" : @"#00FFFF",
            @"Aquamarine" : @"#7FFFD4",
            @"Azure" : @"#F0FFFF",
            @"Beige" : @"#F5F5DC",
            @"Bisque" : @"#FFE4C4",
            @"Black" : @"#000000",
            @"BlanchedAlmond" : @"#FFEBCD",
            @"Blue" : @"#0000FF",
            @"BlueViolet" : @"#8A2BE2",
            @"Brown" : @"#A52A2A",
            @"BurlyWood" : @"#DEB887",
            @"CadetBlue" : @"#5F9EA0",
            @"Chartreuse" : @"#7FFF00",
            @"Chocolate" : @"#D2691E",
            @"Coral" : @"#FF7F50",
            @"CornflowerBlue" : @"#6495ED",
            @"Cornsilk" : @"#FFF8DC",
            @"Crimson" : @"#DC143C",
            @"Cyan" : @"#00FFFF",
            @"DarkBlue" : @"#00008B",
            @"DarkCyan" : @"#008B8B",
            @"DarkGoldenRod" : @"#B8860B",
            @"DarkGray" : @"#A9A9A9",
            @"DarkGrey" : @"#A9A9A9",
            @"DarkGreen" : @"#006400",
            @"DarkKhaki" : @"#BDB76B",
            @"DarkMagenta" : @"#8B008B",
            @"DarkOliveGreen" : @"#556B2F",
            @"DarkOrange" : @"#FF8C00",
            @"DarkOrchid" : @"#9932CC",
            @"DarkRed" : @"#8B0000",
            @"DarkSalmon" : @"#E9967A",
            @"DarkSeaGreen" : @"#8FBC8F",
            @"DarkSlateBlue" : @"#483D8B",
            @"DarkSlateGray" : @"#2F4F4F",
            @"DarkSlateGrey" : @"#2F4F4F",
            @"DarkTurquoise" : @"#00CED1",
            @"DarkViolet" : @"#9400D3",
            @"DeepPink" : @"#FF1493",
            @"DeepSkyBlue" : @"#00BFFF",
            @"DimGray" : @"#696969",
            @"DimGrey" : @"#696969",
            @"DodgerBlue" : @"#1E90FF",
            @"FireBrick" : @"#B22222",
            @"FloralWhite" : @"#FFFAF0",
            @"ForestGreen" : @"#228B22",
            @"Fuchsia" : @"#FF00FF",
            @"Gainsboro" : @"#DCDCDC",
            @"GhostWhite" : @"#F8F8FF",
            @"Gold" : @"#FFD700",
            @"GoldenRod" : @"#DAA520",
            @"Gray" : @"#808080",
            @"Grey" : @"#808080",
            @"Green" : @"#008000",
            @"GreenYellow" : @"#ADFF2F",
            @"HoneyDew" : @"#F0FFF0",
            @"HotPink" : @"#FF69B4",
            @"IndianRed" : @"#CD5C5C",
            @"Indigo" : @"#4B0082",
            @"Ivory" : @"#FFFFF0",
            @"Khaki" : @"#F0E68C",
            @"Lavender" : @"#E6E6FA",
            @"LavenderBlush" : @"#FFF0F5",
            @"LawnGreen" : @"#7CFC00",
            @"LemonChiffon" : @"#FFFACD",
            @"LightBlue" : @"#ADD8E6",
            @"LightCoral" : @"#F08080",
            @"LightCyan" : @"#E0FFFF",
            @"LightGoldenRodYellow" : @"#FAFAD2",
            @"LightGray" : @"#D3D3D3",
            @"LightGrey" : @"#D3D3D3",
            @"LightGreen" : @"#90EE90",
            @"LightPink" : @"#FFB6C1",
            @"LightSalmon" : @"#FFA07A",
            @"LightSeaGreen" : @"#20B2AA",
            @"LightSkyBlue" : @"#87CEFA",
            @"LightSlateGray" : @"#778899",
            @"LightSlateGrey" : @"#778899",
            @"LightSteelBlue" : @"#B0C4DE",
            @"LightYellow" : @"#FFFFE0",
            @"Lime" : @"#00FF00",
            @"LimeGreen" : @"#32CD32",
            @"Linen" : @"#FAF0E6",
            @"Magenta" : @"#FF00FF",
            @"Maroon" : @"#800000",
            @"MediumAquaMarine" : @"#66CDAA",
            @"MediumBlue" : @"#0000CD",
            @"MediumOrchid" : @"#BA55D3",
            @"MediumPurple" : @"#9370DB",
            @"MediumSeaGreen" : @"#3CB371",
            @"MediumSlateBlue" : @"#7B68EE",
            @"MediumSpringGreen" : @"#00FA9A",
            @"MediumTurquoise" : @"#48D1CC",
            @"MediumVioletRed" : @"#C71585",
            @"MidnightBlue" : @"#191970",
            @"MintCream" : @"#F5FFFA",
            @"MistyRose" : @"#FFE4E1",
            @"Moccasin" : @"#FFE4B5",
            @"NavajoWhite" : @"#FFDEAD",
            @"Navy" : @"#000080",
            @"OldLace" : @"#FDF5E6",
            @"Olive" : @"#808000",
            @"OliveDrab" : @"#6B8E23",
            @"Orange" : @"#FFA500",
            @"OrangeRed" : @"#FF4500",
            @"Orchid" : @"#DA70D6",
            @"PaleGoldenRod" : @"#EEE8AA",
            @"PaleGreen" : @"#98FB98",
            @"PaleTurquoise" : @"#AFEEEE",
            @"PaleVioletRed" : @"#DB7093",
            @"PapayaWhip" : @"#FFEFD5",
            @"PeachPuff" : @"#FFDAB9",
            @"Peru" : @"#CD853F",
            @"Pink" : @"#FFC0CB",
            @"Plum" : @"#DDA0DD",
            @"PowderBlue" : @"#B0E0E6",
            @"Purple" : @"#800080",
            @"Red" : @"#FF0000",
            @"RosyBrown" : @"#BC8F8F",
            @"RoyalBlue" : @"#4169E1",
            @"SaddleBrown" : @"#8B4513",
            @"Salmon" : @"#FA8072",
            @"SandyBrown" : @"#F4A460",
            @"SeaGreen" : @"#2E8B57",
            @"SeaShell" : @"#FFF5EE",
            @"Sienna" : @"#A0522D",
            @"Silver" : @"#C0C0C0",
            @"SkyBlue" : @"#87CEEB",
            @"SlateBlue" : @"#6A5ACD",
            @"SlateGray" : @"#708090",
            @"SlateGrey" : @"#708090",
            @"Snow" : @"#FFFAFA",
            @"SpringGreen" : @"#00FF7F",
            @"SteelBlue" : @"#4682B4",
            @"Tan" : @"#D2B48C",
            @"Teal" : @"#008080",
            @"Thistle" : @"#D8BFD8",
            @"Tomato" : @"#FF6347",
            @"Turquoise" : @"#40E0D0",
            @"Violet" : @"#EE82EE",
            @"Wheat" : @"#F5DEB3",
            @"White" : @"#FFFFFF",
            @"WhiteSmoke" : @"#F5F5F5",
            @"Yellow" : @"#FFFF00",
            @"YellowGreen" : @"#9ACD32"
        };
    });
    return namedColors;
}

NS_ASSUME_NONNULL_END
