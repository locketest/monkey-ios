//
//  GPUImageHelper.m
//  Monkey
//
//  Created by 王广威 on 2018/3/20.
//  Copyright © 2018年 Monkey. All rights reserved.
//

#import "GPUImageHelper.h"
#import "InstaFilters.h"

@implementation GPUImageHelper

+ (GPUImageFilterGroup *)sharpFilter {
	GPUImageFilterGroup *groupFilter = [[GPUImageFilterGroup alloc] init];
	GPUImageFilter *emptyFilter = [[GPUImageFilter alloc] init];
	
	[groupFilter setInitialFilters:@[emptyFilter]];
	[groupFilter setTerminalFilter:emptyFilter];
	return groupFilter;
}

+ (GPUImageFilterGroup *)filterGroupWithType:(NSString*)filterType {
    NSArray<NSString*>* filterClasses = @[
        @"IFBrannanFilter",
        @"IFNashvilleFilter",
        @"IFSierraFilter",
        @"IFHudsonFilter",
        @"IFRiseFilter",
        @"IFEarlybirdFilter",
        @"IFAmaroFilter",
        @"IF1977Filter",
        @"IFInkwellFilter",
        @"IFSutroFilter",
        @"IFToasterFilter",
        @"IFHefeFilter",
        @"IFValenciaFilter",
        @"IFXproIIFilter",
        @"IFLordKelvinFilter",
        @"IFWaldenFilter",
        @"IFLomofiFilter",
    ];
    NSArray<NSString*>* filterNames = @[
        @"Brannan",
        @"Nashville",
        @"Sierra",
        @"Hudson",
        @"Rise",
        @"Earlybird",
        @"Amaro",
        @"1977",
        @"Inkwell",
        @"Sutro",
        @"Toaster",
        @"Hefe",
        @"Valencia",
        @"X-Pro II",
        @"Lord Kelvin",
        @"Walden",
        @"Lo-Fi",
    ];
	NSUInteger filterIndex = [filterNames indexOfObject:filterType];
	if (filterIndex != NSNotFound) {
		Class filterClass = NSClassFromString(filterClasses[filterIndex]);
		return [[filterClass alloc] init];
	} else {
		return [self sharpFilter];
	}
}

@end
