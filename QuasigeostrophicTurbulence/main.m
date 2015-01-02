//
//  main.m
//  QuasigeostrophicTurbulence
//
//  Created by Jeffrey J. Early on 10/7/14.
//  Copyright (c) 2014 Jeffrey J. Early. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLNumericalModelingKit/GLNumericalModelingKit.h>
#import <GLOceanKit/GLOceanKit.h>

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		NSURL *outputFile = [[NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]] URLByAppendingPathComponent:@"TurbulenceSpinUp.nc"];
		
		GLFloat domainWidth = 100e3; // m
		NSUInteger nPoints = 2048;
		NSUInteger aspectRatio = 1;
		
		GLDimension *xDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints domainMin:-domainWidth/2.0 length:domainWidth];
		xDim.name = @"x";
		GLDimension *yDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints/aspectRatio domainMin:-domainWidth/(2.0*aspectRatio) length: domainWidth/aspectRatio];
		yDim.name = @"y";
		
		GLEquation *equation = [[GLEquation alloc] init];
		Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithDimensions: @[xDim, yDim] depth: 0.80 latitude: 24.0 equation: equation];
		qg.shouldUseBeta = NO;
		qg.shouldUseSVV = YES;
		qg.shouldAntiAlias = YES;
		qg.shouldForce = YES;
		qg.forcingFraction = 32;
		qg.forcingWidth = 1;
        qg.f_zeta = 10;
        qg.forcingDecorrelationTime = HUGE_VAL;
		qg.thermalDampingFraction = 0.0;
		qg.frictionalDampingFraction = 2.0;
        
        
        qg.outputFile = outputFile;
        qg.shouldAdvectFloats = YES;
        qg.shouldAdvectTracer = NO;
        qg.outputInterval = 86400.;
        
        [qg runSimulationToTime: 100*86400];
	}
    return 0;
}
