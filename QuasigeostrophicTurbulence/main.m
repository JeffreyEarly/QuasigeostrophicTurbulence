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
		NSURL *restartFile = [[NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]] URLByAppendingPathComponent:@"QGMonopole.nc"];
		NSURL *outputFile = [[NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]] URLByAppendingPathComponent:@"QGMonopole.nc"];
		
		GLFloat domainWidth = 100e3; // m
		NSUInteger nPoints = 256;
		NSUInteger aspectRatio = 1;
		
		GLDimension *xDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints domainMin:-domainWidth/2.0 length:domainWidth];
		xDim.name = @"x";
		GLDimension *yDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints/aspectRatio domainMin:-domainWidth/(2.0*aspectRatio) length: domainWidth/aspectRatio];
		yDim.name = @"y";
		
		GLEquation *equation = [[GLEquation alloc] init];
		Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithDimensions: @[xDim, yDim] depth: 0.80 latitude: 24.0 equation: equation];
		//Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithFile:restartFile resolutionDoubling:YES equation: equation];
		qg.shouldUseBeta = NO;
		qg.shouldUseSVV = YES;
		qg.shouldAntiAlias = NO;
		qg.shouldForce = NO;
		qg.forcingFraction = 16;
		qg.forcingWidth = 1;
        qg.f_zeta = 10;
        qg.forcingDecorrelationTime = HUGE_VAL;
		qg.thermalDampingFraction = 0.0;
		qg.frictionalDampingFraction = 2.0;
        
        
        qg.outputFile = outputFile;
        qg.shouldAdvectFloats = NO;
        qg.shouldAdvectTracer = NO;
        qg.outputInterval = 86400./20.;
        
        GLFloat amplitude = .15/qg.N_QG;
        GLFloat length = 5e3/qg.L_QG;
        GLFunction *x = [GLFunction functionOfRealTypeFromDimension: qg.dimensions[0] withDimensions: qg.dimensions forEquation: equation];
        GLFunction *y = [GLFunction functionOfRealTypeFromDimension: qg.dimensions[1] withDimensions: qg.dimensions forEquation: equation];
        GLFunction *r2 = [[x times: x] plus: [y times: y]];
        qg.ssh = [[[r2 times: @(-1.0/(length*length))] exponentiate] times: @(amplitude)];
        
        [qg runSimulationToTime: 10*86400];
	}
    return 0;
}
