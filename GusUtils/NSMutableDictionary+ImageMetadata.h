//
//  NSMutableDictionary+ImageMetadata.h
//
//  Created by Gustavo Ambrozio on 28/2/11.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface NSMutableDictionary (ImageMetadataCategory) 

- (id)initWithImageSampleBuffer:(CMSampleBufferRef) imageDataSampleBuffer;

- (void)setLocation:(CLLocation *)currentLocation;
- (void)setUserComment:(NSString*)comment;
- (void)setDateOriginal:(NSDate *)date;
- (void)setDateDigitized:(NSDate *)date;
- (void)setMake:(NSString*)make model:(NSString*)model software:(NSString*)software;
- (void)setDescription:(NSString*)description;
- (void)setKeywords:(NSString*)keywords;
- (void)setImageOrientarion:(UIImageOrientation)orientation;

@end
