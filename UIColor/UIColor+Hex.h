// UIColor+Hex.h

@interface UIColor (ColorWithHex)

+(UIColor*)colorWithHexValue:(uint)hexValue andAlpha:(float)alpha;
+(UIColor*)colorWithHexString:(NSString *)hexString andAlpha:(float)alpha;

@end
