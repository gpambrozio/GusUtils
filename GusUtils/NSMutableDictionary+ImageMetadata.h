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

/*
 Be careful with this method: because it uses blocks, there's no guarantee that your
 imageMetadata dictionary will be populated when this code runs. In some testing I've 
 done it sometimes runs the code inside the block even before the [library autorelease] 
 is executed. But the first time you run this, the code inside the block will only run 
 on another cycle of the apps main loop. So, if you need to use this info right away, 
 it's better to schedule a method on the run queue for later with:
 
 [self performSelectorOnMainThread: withObject: waitUntilDone:NO];
 */
- (id)initWithInfoFromImagePicker:(NSDictionary *)info;

/*
 Be careful with this method: because it uses blocks, there's no guarantee that your
 imageMetadata dictionary will be populated when this code runs. In some testing I've 
 done it sometimes runs the code inside the block even before the [library autorelease] 
 is executed. But the first time you run this, the code inside the block will only run 
 on another cycle of the apps main loop. So, if you need to use this info right away, 
 it's better to schedule a method on the run queue for later with:
 
 [self performSelectorOnMainThread: withObject: waitUntilDone:NO];
 */
- (id)initFromAssetURL:(NSURL*)assetURL;

- (void)setUserComment:(NSString*)comment;
- (void)setDateOriginal:(NSDate *)date;
- (void)setDateDigitized:(NSDate *)date;
- (void)setMake:(NSString*)make model:(NSString*)model software:(NSString*)software;
- (void)setDescription:(NSString*)description;
- (void)setKeywords:(NSString*)keywords;
- (void)setImageOrientarion:(UIImageOrientation)orientation;
- (void)setDigitalZoom:(CGFloat)zoom;
- (void)setHeading:(CLHeading*)heading;

@property (nonatomic, assign) CLLocation *location;
@property (nonatomic, assign) CLLocationDirection trueHeading;

@end
