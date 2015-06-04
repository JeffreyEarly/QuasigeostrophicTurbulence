//
//  main.m
//  QuasigeostrophicTurbulenceWithRestart
//
//  Created by Jeffrey J. Early on 6/1/15.
//  Copyright (c) 2015 Jeffrey J. Early. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <GLNumericalModelingKit/GLNumericalModelingKit.h>
#import <GLOceanKit/GLOceanKit.h>

typedef NS_ENUM(NSUInteger, ExperimentType) {
	kIsotropicExperimentType = 0,
	kAnisotropicExperimentType = 1
};

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		ExperimentType experiment = kIsotropicExperimentType;
		GLFloat domainWidth = 2500e3; // m
		NSUInteger nPoints = 256;
		NSUInteger aspectRatio = 1;
		
		//NSURL *baseFolder = [NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]];
		NSURL *baseFolder = [NSURL fileURLWithPath: @"/Users/jearly/Desktop/Isotropy/"];
		NSString *baseName = experiment == kIsotropicExperimentType ? @"TurbulenceIsotropic" : @"TurbulenceAnisotropic";
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		GLDimension *xDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints domainMin:-domainWidth/2.0 length:domainWidth];
		xDim.name = @"x";
		GLDimension *yDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints/aspectRatio domainMin:-domainWidth/(2.0*aspectRatio) length: domainWidth/aspectRatio];
		yDim.name = @"y";
		
		GLEquation *equation = [[GLEquation alloc] init];
		
		NSURL *restartURLx1 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x1.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx1.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithDimensions: @[xDim, yDim] depth: 0.80 latitude: 24 equation: equation];
			qgSpinup.shouldUseBeta = experiment == kIsotropicExperimentType ? NO : YES;
			qgSpinup.shouldUseSVV = YES;
			qgSpinup.shouldAntiAlias = YES;
			qgSpinup.shouldForce = YES;
			qgSpinup.forcingFraction = 4;
			qgSpinup.forcingWidth = 1;
			qgSpinup.f_zeta = 0.5;
			qgSpinup.forcingDecorrelationTime = HUGE_VAL;
			qgSpinup.thermalDampingFraction = 4.0;
			qgSpinup.frictionalDampingFraction = 0.0; //8.0;
			
			qgSpinup.outputFile = restartURLx1;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
			qgSpinup.outputInterval = 100.*86400.;
			
			[qgSpinup runSimulationToTime: 30001.0*86400.0];
		}
		
		
		
		NSURL *restartURLx2 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x2.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx2.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx1 resolutionDoubling:NO equation: equation];
			qgSpinup.shouldForce = YES;
			
			qgSpinup.outputFile = restartURLx2;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
			qgSpinup.outputInterval = 100.*86400.;
			
			GLFloat maxTime = 25001.0*86400.0;
			[qgSpinup runSimulationToTime: maxTime];
		}
		
		NSURL *restartURLx4 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x4.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx4.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx2 resolutionDoubling:YES equation: equation];
			qgSpinup.shouldForce = YES;
			
			qgSpinup.outputFile = restartURLx4;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
			qgSpinup.outputInterval = 10.*86400.;
			
			[qgSpinup runSimulationToTime: 1001.*86400.];
		}
		
//		NSURL *restartURLx8 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x8.nc"]];
//		if (![fileManager fileExistsAtPath: restartURLx8.path])
//		{
//			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx4 resolutionDoubling:YES equation: equation];
//			qgSpinup.shouldForce = YES;
//			
//			qgSpinup.outputFile = restartURLx8;
//			qgSpinup.shouldAdvectFloats = NO;
//			qgSpinup.shouldAdvectTracer = NO;
//			qgSpinup.outputInterval = 1.*86400.;
//			
//			[qgSpinup runSimulationToTime: 101.*86400.];
//		}
		
		Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithFile:restartURLx4 resolutionDoubling:NO equation: equation];
		qg.shouldForce = YES;
		
		GLDimension *xDimND = qg.dimensions[0];
		GLDimension *yDimND = qg.dimensions[1];
		NSUInteger floatStride = 32;
		GLDimension *xFloatDim = [[GLDimension alloc] initDimensionWithGrid: xDimND.gridType nPoints: xDimND.nPoints/floatStride domainMin: xDimND.domainMin length:xDimND.domainLength];
		xFloatDim.name = @"x-float";
		GLDimension *yFloatDim = [[GLDimension alloc] initDimensionWithGrid: yDimND.gridType nPoints: yDimND.nPoints/floatStride domainMin: yDimND.domainMin length:yDimND.domainLength];
		yFloatDim.name = @"y-float";
		
		NSArray *floatDims = @[xFloatDim, yFloatDim];
		qg.xPosition = [GLFunction functionOfRealTypeFromDimension: xFloatDim withDimensions: floatDims forEquation: qg.equation];
		qg.yPosition = [GLFunction functionOfRealTypeFromDimension: yFloatDim withDimensions: floatDims forEquation: qg.equation];
		
		qg.outputFile = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @".nc"]];
		qg.shouldWriteSSH = NO;
		qg.shouldAdvectFloats = YES;
		qg.shouldAdvectTracer = NO;
		qg.outputInterval = 86400./4.;
		
		[qg runSimulationToTime: 10001*86400];
	}
	return 0;
}
