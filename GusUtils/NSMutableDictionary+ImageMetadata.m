//
//  NSMutableDictionary+ImageMetadata.m
//
//  Created by Gustavo Ambrozio on 28/2/11.
//

#import "NSMutableDictionary+ImageMetadata.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation NSMutableDictionary (ImageMetadataCategory)

@dynamic trueHeading;
@dynamic location;

- (NSString *)getUTCFormattedDate:(NSDate *)localDate {

    static NSDateFormatter *dateFormatter;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    }
    NSString *dateString = [dateFormatter stringFromDate:localDate];
    return dateString;
}

- (id)initWithImageSampleBuffer:(CMSampleBufferRef) imageDataSampleBuffer {
    
    // Dictionary of metadata is here
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
    
    // Just init with it....
    self = [self initWithDictionary:(NSDictionary*)metadataDict];
    
    // Release it
    CFRelease(metadataDict);
    return self;
}

- (id)initWithInfoFromImagePicker:(NSDictionary *)info {
    
    if ((self = [self init])) {
        
        // Key UIImagePickerControllerReferenceURL only exists in iOS 4.1
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.1f) {
            
            NSURL* assetURL = nil;
            if ((assetURL = [info objectForKey:UIImagePickerControllerReferenceURL])) {
            
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library assetForURL:assetURL 
                         resultBlock:^(ALAsset *asset)  {
                             NSDictionary *metadata = asset.defaultRepresentation.metadata;
                             [self addEntriesFromDictionary:metadata];
                         }
                        failureBlock:^(NSError *error) {
                        }];
                [library autorelease];
            }
            else {
                NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
                if (metadata)
                    [self addEntriesFromDictionary:metadata];
            }
        }
    }
    
    return self;
}

- (id)initFromAssetURL:(NSURL*)assetURL {

    if ((self = [self init])) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:assetURL 
                 resultBlock:^(ALAsset *asset)  {
                     NSDictionary *metadata = asset.defaultRepresentation.metadata;
                     [self addEntriesFromDictionary:metadata];
                 }
                failureBlock:^(NSError *error) {
                }];
        [library autorelease];
    }
    
    return self;
}

// Mostly from here: http://stackoverflow.com/questions/3884060/need-help-in-saving-geotag-info-with-photo-on-ios4-1
- (void)setLocation:(CLLocation *)location {
    
    if (location) {
        
        CLLocationDegrees exifLatitude  = location.coordinate.latitude;
        CLLocationDegrees exifLongitude = location.coordinate.longitude;

        NSString *latRef;
        NSString *lngRef;
        if (exifLatitude < 0.0) {
            exifLatitude = exifLatitude * -1.0f;
            latRef = @"S";
        } else {
            latRef = @"N";
        }
        
        if (exifLongitude < 0.0) {
            exifLongitude = exifLongitude * -1.0f;
            lngRef = @"W";
        } else {
            lngRef = @"E";
        }
        
        NSMutableDictionary *locDict = [[NSMutableDictionary alloc] init];
        if ([self objectForKey:(NSString*)kCGImagePropertyGPSDictionary]) {
            [locDict addEntriesFromDictionary:[self objectForKey:(NSString*)kCGImagePropertyGPSDictionary]];
        }
        [locDict setObject:[self getUTCFormattedDate:location.timestamp] forKey:(NSString*)kCGImagePropertyGPSTimeStamp];
        [locDict setObject:latRef forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        [locDict setObject:[NSNumber numberWithFloat:exifLatitude] forKey:(NSString*)kCGImagePropertyGPSLatitude];
        [locDict setObject:lngRef forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        [locDict setObject:[NSNumber numberWithFloat:exifLongitude] forKey:(NSString*)kCGImagePropertyGPSLongitude];
        [locDict setObject:[NSNumber numberWithFloat:location.horizontalAccuracy] forKey:(NSString*)kCGImagePropertyGPSDOP];
        [locDict setObject:[NSNumber numberWithFloat:location.altitude] forKey:(NSString*)kCGImagePropertyGPSAltitude];
        
        [self setObject:locDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
        [locDict release];    
    }
}

// Set heading while preserving location metadata, if it exists.
- (void)setHeading:(CLHeading *)locatioHeading {
    
    if (locatioHeading) {
        
        CLLocationDirection trueDirection = locatioHeading.trueHeading;
        NSMutableDictionary *locDict = [[NSMutableDictionary alloc] init];
        if ([self objectForKey:(NSString*)kCGImagePropertyGPSDictionary]) {
            [locDict addEntriesFromDictionary:[self objectForKey:(NSString*)kCGImagePropertyGPSDictionary]];
        }
        [locDict setObject:@"T" forKey:(NSString*)kCGImagePropertyGPSImgDirectionRef];
        [locDict setObject:[NSNumber numberWithFloat:trueDirection] forKey:(NSString*)kCGImagePropertyGPSImgDirection];

        [self setObject:locDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
        [locDict release];    
    }
}

- (CLLocation*)location {
    NSDictionary *locDict = [self objectForKey:(NSString*)kCGImagePropertyGPSDictionary];
    if (locDict) {
        
        CLLocationDegrees lat = [[locDict objectForKey:(NSString*)kCGImagePropertyGPSLatitude] floatValue];
        CLLocationDegrees lng = [[locDict objectForKey:(NSString*)kCGImagePropertyGPSLongitude] floatValue];
        NSString *latRef = [locDict objectForKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        NSString *lngRef = [locDict objectForKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        
        if ([@"S" isEqualToString:latRef])
            lat *= -1.0f;
        if ([@"W" isEqualToString:lngRef])
            lng *= -1.0f;
        
        CLLocation *location = [[[CLLocation alloc] initWithLatitude:lat longitude:lng] autorelease];
        return location;
    }
    
    return nil;
}

- (CLLocationDirection)trueHeading {
    NSDictionary *locDict = [self objectForKey:(NSString*)kCGImagePropertyGPSDictionary];
    CLLocationDirection heading = 0;
    if (locDict) {
        heading = [[locDict objectForKey:(NSString*)kCGImagePropertyGPSImgDirection] doubleValue];
    }
    
    return heading;
}

- (NSMutableDictionary *)dictionaryForKey:(CFStringRef)key {
    NSDictionary *dict = [self objectForKey:(NSString*)key];
    NSMutableDictionary *mutableDict;
    
    if (dict == nil) {
        mutableDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [self setObject:mutableDict forKey:(NSString*)key];
    } else {
        if ([dict isMemberOfClass:[NSMutableDictionary class]])
        {
            mutableDict = (NSMutableDictionary*)dict;
        } else {
            mutableDict = [[dict mutableCopy] autorelease];
            [self setObject:mutableDict forKey:(NSString*)key];
        }
    }
    
    return mutableDict;
}


#define EXIF_DICT [self dictionaryForKey:kCGImagePropertyExifDictionary]
#define TIFF_DICT [self dictionaryForKey:kCGImagePropertyTIFFDictionary]
#define IPTC_DICT [self dictionaryForKey:kCGImagePropertyIPTCDictionary]


- (void)setUserComment:(NSString*)comment {
    [EXIF_DICT setObject:comment forKey:(NSString*)kCGImagePropertyExifUserComment];
}

- (void)setDateOriginal:(NSDate *)date {
    NSString *dateString = [self getUTCFormattedDate:date];
    [EXIF_DICT setObject:dateString forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
    [TIFF_DICT setObject:dateString forKey:(NSString*)kCGImagePropertyTIFFDateTime];
}

- (void)setDateDigitized:(NSDate *)date {
    NSString *dateString = [self getUTCFormattedDate:date];
    [EXIF_DICT setObject:dateString forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
}

- (void)setMake:(NSString*)make model:(NSString*)model software:(NSString*)software {
    NSMutableDictionary *tiffDict = TIFF_DICT;
    [tiffDict setObject:make forKey:(NSString*)kCGImagePropertyTIFFMake];
    [tiffDict setObject:model forKey:(NSString*)kCGImagePropertyTIFFModel];
    [tiffDict setObject:software forKey:(NSString*)kCGImagePropertyTIFFSoftware];
}

- (void)setDescription:(NSString*)description {
    [TIFF_DICT setObject:description forKey:(NSString*)kCGImagePropertyTIFFImageDescription];
}

- (void)setKeywords:(NSString*)keywords {
    [IPTC_DICT setObject:keywords forKey:(NSString*)kCGImagePropertyIPTCKeywords];
}

- (void)setDigitalZoom:(CGFloat)zoom {
    [EXIF_DICT setObject:[NSNumber numberWithFloat:zoom] forKey:(NSString*)kCGImagePropertyExifDigitalZoomRatio];
}


/* The intended display orientation of the image. If present, the value 
 * of this key is a CFNumberRef with the same value as defined by the 
 * TIFF and Exif specifications.  That is:
 *   1  =  0th row is at the top, and 0th column is on the left.  
 *   2  =  0th row is at the top, and 0th column is on the right.  
 *   3  =  0th row is at the bottom, and 0th column is on the right.  
 *   4  =  0th row is at the bottom, and 0th column is on the left.  
 *   5  =  0th row is on the left, and 0th column is the top.  
 *   6  =  0th row is on the right, and 0th column is the top.  
 *   7  =  0th row is on the right, and 0th column is the bottom.  
 *   8  =  0th row is on the left, and 0th column is the bottom.  
 * If not present, a value of 1 is assumed. */ 

// Reference: http://sylvana.net/jpegcrop/exif_orientation.html
- (void)setImageOrientation:(UIImageOrientation)orientation {
    int o = 1;
    switch (orientation) {
        case UIImageOrientationUp:
            o = 1;
            break;
            
        case UIImageOrientationDown:
            o = 3;
            break;
            
        case UIImageOrientationLeft:
            o = 8;
            break;
            
        case UIImageOrientationRight:
            o = 6;
            break;
            
        case UIImageOrientationUpMirrored:
            o = 2;
            break;
            
        case UIImageOrientationDownMirrored:
            o = 4;
            break;
            
        case UIImageOrientationLeftMirrored:
            o = 5;
            break;
            
        case UIImageOrientationRightMirrored:
            o = 7;
            break;
    }
    
    [self setObject:[NSNumber numberWithInt:o] forKey:(NSString*)kCGImagePropertyOrientation];
}



@end
