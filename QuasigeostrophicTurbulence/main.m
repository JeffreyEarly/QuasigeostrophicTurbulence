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
		//NSURL *outputFile = [[NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]] URLByAppendingPathComponent:@"TurbulenceSpinUp.nc"];
		NSURL *outputFile = [NSURL fileURLWithPath: @"/Volumes/RadiativeTr/AnisotropicTurbulenceSpinUp.nc"];
		
		GLFloat domainWidth = (2*M_PI)*2*611e3; // m
		NSUInteger nPoints = 1024;
		NSUInteger aspectRatio = 1;
		
		GLDimension *xDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints domainMin:-domainWidth/2.0 length:domainWidth];
		xDim.name = @"x";
		GLDimension *yDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints/aspectRatio domainMin:-domainWidth/(2.0*aspectRatio) length: domainWidth/aspectRatio];
		yDim.name = @"y";
		
		GLEquation *equation = [[GLEquation alloc] init];
		Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithDimensions: @[xDim, yDim] depth: 0.80 latitude: 1.8 equation: equation];
		qg.shouldUseBeta = YES;
		qg.shouldUseSVV = YES;
		qg.shouldAntiAlias = YES;
		qg.shouldForce = YES;
		qg.forcingFraction = 8;
		qg.forcingWidth = 1;
        qg.f_zeta = .1;
        qg.forcingDecorrelationTime = HUGE_VAL;
		qg.thermalDampingFraction = 0.0;
		qg.frictionalDampingFraction = 3.0;
        
        
        qg.outputFile = outputFile;
        qg.shouldAdvectFloats = YES;
        qg.shouldAdvectTracer = NO;
        qg.outputInterval = 86400./2.;
        
        [qg runSimulationToTime: 2500*86400];
	}
    return 0;
}
