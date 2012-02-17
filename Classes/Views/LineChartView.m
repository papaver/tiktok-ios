//
//  LineChartView.m
//  TikTok
//
//  Created by Moiz Merchant on 02/16/11.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "LineChartView.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

void
calculateMinMaxForData(NSArray *data, CGFloat *min, CGFloat* max);

void
CGContextAddEllipses(CGContextRef context, CGFloat diameter,
                     CGPoint *points, NSUInteger count);

void
drawLinePlotWithLineWidth(CGContextRef context, CGFloat lineWidth,
                          CGPoint *points, NSUInteger count);

void
drawLinePlotGradient(CGContextRef context, CGGradientRef gradient,
                     CGPoint start, CGPoint end, CGPoint *points, NSUInteger count);

//------------------------------------------------------------------------------
// helper functions
//------------------------------------------------------------------------------

void
calculateMinMaxForData(NSArray *data, CGFloat *min, CGFloat* max)
{
    // find the min/max in the data values
    CGFloat _min =  MAXFLOAT;
    CGFloat _max = -MAXFLOAT;
    for (NSNumber *value in data) {
        _min = MIN(_min, value.doubleValue);
        _max = MAX(_max, value.doubleValue);
    }

    // add a buffer to the min max values
    CGFloat range        = _max - _min;
    CGFloat rangeBuffer  = range * .1;
    _min                -= rangeBuffer;
    _max                += rangeBuffer;

    // save the values
    *min = _min;
    *max = _max;
}

//------------------------------------------------------------------------------

void
CGContextAddEllipses(CGContextRef context, CGFloat diameter,
                     CGPoint *points, NSUInteger count)
{
    CGRect circle;
    CGFloat radius = diameter * 0.5;
    for (NSUInteger index = 0; index < count; ++index) {

        // center ellipse around center of point
        circle.origin.x    = points[index].x - radius;
        circle.origin.y    = points[index].y - radius;
        circle.size.width  = diameter;
        circle.size.height = diameter;

        // add ellipse to context
        CGContextAddEllipseInRect(context, circle);
    }
}

//------------------------------------------------------------------------------

void
drawLinePlotWithLineWidth(CGContextRef context, CGFloat lineWidth,
                          CGPoint *points, NSUInteger count)
{
    // setup line settings
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, lineWidth);

    // draw the lines and the points with a stroke
    CGContextBeginPath(context);
    CGContextAddLines(context, points, count);
    CGContextAddEllipses(context, lineWidth * 2.0, &points[1], count - 2);
    CGContextDrawPath(context, kCGPathStroke);

    // remove the shadow and draw filled in points
    CGContextSetShadowWithColor(context, CGSizeMake(0.0, 0.0), 0.0, nil);
    CGContextBeginPath(context);
    CGContextAddEllipses(context, lineWidth * 2.0, &points[1], count - 2);
    CGContextDrawPath(context, kCGPathFill);
}

//------------------------------------------------------------------------------

void
drawLinePlotGradient(CGContextRef context, CGGradientRef gradient,
                     CGPoint start, CGPoint end, CGPoint *points, NSUInteger count)
{
    // create a clipping path
    CGContextBeginPath(context);
    CGContextAddLines(context, points, count);
    CGContextClosePath(context);

    // save context so we can push on the clipping path
    CGContextSaveGState(context);
    CGContextClip(context);

    // render the gradient
    CGContextDrawLinearGradient(context, gradient, start, end, 0);

    // restore the state, pushes the clipping path off
    CGContextRestoreGState(context);
}

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LineChartView ()
    - (void) drawGridLines:(CGRect)rect;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LineChartView

//------------------------------------------------------------------------------

@synthesize data = mData;

//------------------------------------------------------------------------------

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

//------------------------------------------------------------------------------

- (void) drawGridLines:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint topLeft      = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint topRight     = CGPointMake(topLeft.x + rect.size.width, rect.origin.y);
    NSUInteger divisions = 5;

    // draw grid lines at the requested intervals
    CGPoint left, right;
    CGFloat yInterval = rect.size.height / divisions;
    for (NSUInteger index = 0; index <= divisions; ++index) {

        // calculate the left and right points
        left     = topLeft;
        left.y  += yInterval * index;
        right    = topRight;
        right.y += yInterval * index;

        // draw the grid lines
        CGContextSetLineWidth(context, 1.0);
        CGContextSetRGBStrokeColor(context, 0.4f, 0.4f, 0.4f, 0.1f);
        CGContextMoveToPoint(context, left.x, left.y);
        CGContextAddLineToPoint(context, right.x, right.y);
        CGContextStrokePath(context);
    }
}

//------------------------------------------------------------------------------

- (void) drawRect:(CGRect)rect
{
    if (!self.data.count) return;

    // setup drawing context
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    // calculate graph drawing area
    CGFloat buffer   = 10.0;
    CGRect gridFrame = rect;
    gridFrame.origin.x    += buffer;
    gridFrame.origin.y    += buffer;
    gridFrame.size.width  -= buffer * 2.0;
    gridFrame.size.height -= buffer * 2.0;

    // draw grid lines
    [self drawGridLines:gridFrame];

    // find the min/max in the data values
    CGFloat min, max;
    calculateMinMaxForData(self.data, &min, &max);

    // calculate granularity of the two axes
    CGFloat xInterval = gridFrame.size.width / (self.data.count - 1);
    CGFloat yInterval = gridFrame.size.height / (max - min);

    // calcuate the extents
    CGFloat top    = gridFrame.origin.y;
    CGFloat bottom = gridFrame.origin.y + gridFrame.size.height;
    CGFloat left   = gridFrame.origin.x;
    CGFloat right  = gridFrame.origin.x + gridFrame.size.width;

    // calculate the initial point on the bottom left
    CGPoint bottomLeft  = CGPointMake(left, bottom);
    CGPoint bottomRight = CGPointMake(right, bottom);

    // create an array of points
    CGFloat count   = self.data.count + 2;
    CGPoint *points = malloc(sizeof(CGPoint) * count);
    for (NSUInteger index = 1; index <= self.data.count; ++index) {
        NSNumber *value  = [self.data objectAtIndex:index - 1];
        points[index]    = bottomLeft;
        points[index].x += xInterval * (index - 1);
        points[index].y -= yInterval * value.doubleValue;
    }

    // set first and last points to bottom left and right
    points[0]                   = bottomLeft;
    points[self.data.count + 1] = bottomRight;

    // setup the gradient to use
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        204.0 / 255.0, 224.0 / 255.0, 244.0 / 255.0, 1.00,
         29.0 / 255.0, 156.0 / 255.0, 215.0 / 255.0, 0.50,
          0.0 / 255.0,  50.0 / 255.0, 126.0 / 255.0, 0.00,
    };
    CGGradientRef gradient =
        CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors) / (sizeof(colors[0]) * 4));
    CGColorSpaceRelease(rgb);

    // draw the gradient first
    CGFloat middle = (left - right) * 0.5;
    CGPoint start  = CGPointMake(middle, top);
    CGPoint end    = CGPointMake(middle, bottom);
    drawLinePlotGradient(context, gradient, start, end, points, count);
    CGGradientRelease(gradient);

    // draw the line plot
    CGColorRef shadowColor = [[UIColor lightGrayColor] CGColor];
    CGContextSetFillColorWithColor(context, [[UIColor greenColor] CGColor]);
    CGContextSetShadowWithColor(context, CGSizeMake(-1.0, -1.0), 1.0, shadowColor);
    CGContextSetStrokeColorWithColor(context, [[UIColor greenColor] CGColor]);
    drawLinePlotWithLineWidth(context, 2.0, &points[1], count - 2);

    // draw the axes
    CGFloat extra = buffer * 0.5;
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, left - extra, bottom);
    CGContextAddLineToPoint(context, right + extra, bottom);
    CGContextMoveToPoint(context, left, bottom + extra);
    CGContextAddLineToPoint(context, left, top - extra);
    CGContextStrokePath(context);

    // cleanup
    free(points);
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mData release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
