//
//  DrawBoard.m
//  draw board
//
//  Created by 阿城 on 15/10/11.
//  Copyright © 2015年 阿城. All rights reserved.
//

#import "DrawBoard.h"
#import "lineWidth.h"
#import "PathStyle.h"
#import "toolView.h"
#import "painter.h"

@interface DrawBoard ()

@property (nonatomic, strong) NSMutableArray* pathArr;
@property (nonatomic, strong) NSMutableArray* pathStyle;

@property (nonatomic, strong) UIBezierPath* currentPath;
@property (nonatomic, strong) PathStyle* currentPathStyle;
@property (nonatomic, assign) CGPoint currentPoint;

@property (nonatomic, strong) UIColor* currentColor;
@property (nonatomic, assign) CGFloat currentWidth;
@property (nonatomic, assign) PrintStyle printStyle;
@property (nonatomic, assign) DrawStyle drawStyle;

//控制点
@property (nonatomic, assign) CGPoint one;
@property (nonatomic, assign) CGPoint two;
@property (nonatomic, assign) CGPoint three;

//判断
@property (nonatomic, assign) BOOL onOne;
@property (nonatomic, assign) BOOL onTwo;
@property (nonatomic, assign) BOOL onThree;
@property (nonatomic, assign) BOOL onDraw;

//工具条
@property (nonatomic, weak) toolView* toolBar;
@property (nonatomic, weak) lineWidth* lineWidth;
@property (nonatomic ,weak) painter* colorPaint;

@property (nonatomic, strong) UIColor *lastColor;

@end

@implementation DrawBoard

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (NSMutableArray*)pathArr
{
    
    if (!_pathArr) {
        _pathArr = [NSMutableArray array];
    }
    return _pathArr;
}

- (NSMutableArray*)pathStyle
{
    if (!_pathStyle) {
        _pathStyle = [NSMutableArray array];
    }
    return _pathStyle;
}

- (void)didMoveToSuperview
{
    //初始化
    [self creatBtn];
    _currentColor = [UIColor blackColor];
    _currentWidth = kDefaultLineWidth;
    _printStyle = PrintStyleStrock;
    _drawStyle = DrawStyleFreedomLine;
    // tool bar
    [self creatToolBar];
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    //创建path
    UIBezierPath* path = [UIBezierPath bezierPath];
    [self.pathArr addObject:path];
    _currentPath = path;
    
    //橡皮擦
    if (_drawStyle == DrawStyleRubber) {
        _currentColor = self.backgroundColor;
    }
    
    //创建绘图style
    _currentPathStyle = [PathStyle new];
    [self.pathStyle addObject:_currentPathStyle];
    _currentPathStyle.color = _currentColor;
    _currentPathStyle.width = _currentWidth;
    _currentPathStyle.drawStyle = _drawStyle;
    _currentPathStyle.printStyle = _printStyle;
    
    //获取当前点
    _currentPoint = [touches.anyObject locationInView:self];
    
    switch (_drawStyle) {
            //自由曲线
        case DrawStyleFreedomLine:
        case DrawStyleRubber:
            [self drawFreedomLineTouchBegin];
            break;
            //其他
        default:
            [self drawLineTouchBegin];
            break;
    }
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    _currentPoint = [touches.anyObject locationInView:self];
    
    switch (_drawStyle) {
            //自由曲线
        case DrawStyleFreedomLine:
        case DrawStyleRubber:
            [self drawFreedomLineTouchMove];
            break;
            //直线 、矩形
        case DrawStyleLine:
        case DrawStyleRectangle:
            [self drawLineTouchMove];
            break;
            //圆、椭圆
        case DrawStyleCircle:
        case DrawStyleOval:
            [self drawCircleTouchMove];
            break;
            //样条曲线、三角形
        case DrawStyleCurve:
        case DrawStyleTriangle:
            [self drawCuverTouchMove];
            break;
        default:
            break;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    if (CGSizeEqualToSize(_currentPath.bounds.size, CGSizeZero)) {
        [_pathArr removeObject:_currentPath];
        [_pathStyle removeObjectAtIndex:_pathStyle.count - 1];
    }
    switch (_drawStyle) {
        case DrawStyleFreedomLine:
        case DrawStyleRubber:
            break;
        default:
            [self drawLineTouchEnd];
            break;
    }
}

- (void)drawRect:(CGRect)rect
{
    for (int i = 0; i < self.pathArr.count; i++) {
        UIBezierPath* path = _pathArr[i];
        PathStyle* style = _pathStyle[i];
        //设置style
        [path setLineWidth:style.width];
        [style.color setStroke];
        //美化
        [path setLineCapStyle:kCGLineCapRound];
        [path setLineJoinStyle:kCGLineJoinRound];
        //渲染
        if (style.printStyle == PrintStyleStrock) {
            [path stroke];
        }
        else {
            [path fill];
        }
    };
    switch (_drawStyle) {
        case DrawStyleLine:
            [self drawLinePath];
            break;
        case DrawStyleCircle:
            [self drawCirclePath];
            break;
        case DrawStyleRectangle:
            [self drawRectanglePath];
            break;
        case DrawStyleOval:
            [self drawOvalPath];
            break;
        case DrawStyleCurve:
            [self drawCuverPath];
            break;
        case DrawStyleTriangle:
            [self drawTrianglePath];
            break;
        default:
            break;
    }
}

- (void)creatBtn
{
    CGFloat H = 49;
    CGFloat Y = self.bounds.size.height - H;
    CGFloat W = self.bounds.size.width;
    CGFloat btnW = W / 2;
    
    UIView* bar = [[UIView alloc] initWithFrame:CGRectMake(0, Y, W, H)];
    bar.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:bar];
    
    UIButton* clean = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, btnW, H)];
    [clean setTitle:@"清除" forState:UIControlStateNormal];
    [clean addTarget:self
              action:@selector(cleanClick:)
    forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:clean];
    
    UIButton* change =
    [[UIButton alloc] initWithFrame:CGRectMake(btnW, 0, btnW, H)];
    [change setTitle:@"工具" forState:UIControlStateNormal];
    [change addTarget:self
               action:@selector(toolClick)
     forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:change];
    
    //颜色
    painter *paint = [painter new];
    paint.bounds = CGRectMake(0, 0, 150, 150);
    paint.center = CGPointMake(self.bounds.size.width * 0.5, -0.5 * paint.bounds.size.height );
    [self addSubview:paint];
    _colorPaint = paint;
    paint.colBlock = ^(UIColor *col){
        _currentColor = col;
        _lastColor = _currentColor;
        
    };
    //设置线宽
    lineWidth* lineView =
    [[NSBundle mainBundle] loadNibNamed:@"lineWidth"
                                  owner:nil
                                options:nil][0];
    lineView.widthBlock = ^(CGFloat width) {
        _currentWidth = width;
    };
    
    lineView.frame = CGRectMake(0, 0, self.bounds.size.width, 60);
    [self addSubview:lineView];
    _lineWidth = lineView;
    
    _lineWidth.transform = CGAffineTransformTranslate(_lineWidth.transform, 0, -_colorPaint.bounds.size.height);
    _colorPaint.transform = CGAffineTransformTranslate(_colorPaint.transform, 0, -_colorPaint.bounds.size.height);
    
}

- (void)creatToolBar
{
    toolView* toolBar = [[[NSBundle mainBundle] loadNibNamed:@"toolView"
                                                       owner:nil
                                                     options:nil] lastObject];
    [self addSubview:toolBar];
    toolBar.center = CGPointMake(self.bounds.size.width + toolBar.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    _toolBar = toolBar;
    // tool btn type
    _toolBar.toolBlock = ^(DrawStyle type) {
        _drawStyle = type;
        [self cancelClick];
        _currentColor = _lastColor;
    };
    //确定
    
    _toolBar.cirtainBlock = ^() {
        [self cirtainClick];
    };
    //取消
    _toolBar.cancelBlock = ^() {
        [self cancelClick];
    };
    //线宽、颜色
    _toolBar.lineWidthBlock = ^() {
        [UIView animateWithDuration:0.5
                         animations:^{
                             if (CGAffineTransformIsIdentity(_lineWidth.transform)) {
                                 _lineWidth.transform = CGAffineTransformMakeTranslation(
                                                                                         0, -_lineWidth.bounds.size.height);
                             }
                             else {
                                 _lineWidth.transform = CGAffineTransformIdentity;
                             }
                             if (CGAffineTransformIsIdentity(_colorPaint.transform)) {
                                 _colorPaint.transform = CGAffineTransformMakeTranslation(
                                                                                          0, _colorPaint.bounds.size.height);
                             }
                             else {
                                 _colorPaint.transform = CGAffineTransformIdentity;
                             }
                         }];
    };
   
}

#pragma mark-------------------按钮点击--------------
- (void)cleanClick:(UIButton*)btn
{
    [_pathArr removeAllObjects];
    [self setNeedsDisplay];
}

- (void)cirtainClick
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    switch (_drawStyle) {
        case DrawStyleLine:
            path = [self drawLine];
            break;
        case DrawStyleCircle:
            path = [self drawCircle];
            break;
        case DrawStyleRectangle:
            path = [self drawRectangle];
            break;
        case DrawStyleOval:
            path = [self drawOval];
            break;
        case DrawStyleCurve:
            path = [self drawCuver];
            break;
        case DrawStyleTriangle:
            path = [self drawTriangle];
            break;
        default:
            break;
    };
    
    if (_drawStyle == DrawStyleRubber) {
        _currentColor = self.backgroundColor;
    }
    
    [_pathArr addObject:path];
    [_pathStyle addObject:_currentPathStyle];
    
    _onDraw = 0;
    _one = CGPointZero;
    _two = CGPointZero;
    _three = CGPointZero;
    
    [self setNeedsDisplay];
}

- (void)cancelClick
{
    _onDraw = 0;
    _one = CGPointZero;
    _two = CGPointZero;
    _three = CGPointZero;
    
    [self setNeedsDisplay];
}

- (void)toolClick
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         if (CGAffineTransformIsIdentity(_toolBar.transform)) {
                             _toolBar.transform = CGAffineTransformTranslate(_toolBar.transform, -_toolBar.bounds.size.width, 0);
                             _lineWidth.transform = CGAffineTransformTranslate(_lineWidth.transform, 0, _colorPaint.bounds.size.height);
                             _colorPaint.transform = CGAffineTransformTranslate(_colorPaint.transform, 0, _colorPaint.bounds.size.height);
                         }
                         else {
                             _toolBar.transform = CGAffineTransformIdentity;
                             _lineWidth.transform = CGAffineTransformTranslate(_lineWidth.transform, 0, -_colorPaint.bounds.size.height);
                             _colorPaint.transform = CGAffineTransformTranslate(_colorPaint.transform, 0, -_colorPaint.bounds.size.height);
                         }
                     }];
}

#pragma mark-------------------自由线--------------
//自由线-----开始触摸
- (void)drawFreedomLineTouchBegin
{
    [_currentPath moveToPoint:_currentPoint];
}
//自由线-----移动
- (void)drawFreedomLineTouchMove
{
    UIBezierPath* path = _currentPath;
    [path addLineToPoint:_currentPoint];
}
#pragma mark-------------------画线----------------
//画线-----开始触摸
- (void)drawLineTouchBegin
{
    if (CGPointEqualToPoint(_one, CGPointZero)) {
        _one = _currentPoint;
        _two = _one;
    }
    if (_onDraw) {
        _onOne = [self selectPoint:_currentPoint OnPoint:_one];
        _onTwo = [self selectPoint:_currentPoint OnPoint:_two];
        _onThree = [self selectPoint:_currentPoint OnPoint:_three];
    }
}
//画线-----移动
- (void)drawLineTouchMove
{
    if (!_onDraw) {
        _two = _currentPoint;
    }
    else {
        _one = _onOne ? _currentPoint : _one;
        _two = _onTwo ? _currentPoint : _two;
    }
}
//画线-----结束触摸
- (void)drawLineTouchEnd
{
    if (!CGPointEqualToPoint(_two, _one)) {
        _onDraw = 1;
    }
}
//画线-----
- (UIBezierPath*)drawLine
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:_one];
    [path addLineToPoint:_two];
    return path;
}
//画线-----渲染
- (void)drawLinePath
{
    UIBezierPath* cir1 = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir1 fill];
    UIBezierPath* cir2 = [UIBezierPath bezierPathWithArcCenter:_two
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir2 fill];
    
    [[self drawLine] stroke];
}
#pragma mark-------------------画圆----------------
//画圆-----移动
- (void)drawCircleTouchMove
{
    if (!_onDraw) {
        _two = _currentPoint;
    }
    else {
        if (_onOne) {
            _two.x += _currentPoint.x - _one.x;
            _two.y += _currentPoint.y - _one.y;
            _one = _currentPoint;
        }
        _two = _onTwo ? _currentPoint : _two;
    }
}
//画圆-----
- (UIBezierPath*)drawCircle
{
    CGFloat radius = sqrt(pow((_one.x - _two.x), 2) + pow((_one.y - _two.y), 2));
    UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:radius
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    return path;
}
//画圆-----渲染
- (void)drawCirclePath
{
    UIBezierPath* cir1 = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir1 fill];
    UIBezierPath* cir2 = [UIBezierPath bezierPathWithArcCenter:_two
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir2 fill];
    UIBezierPath* line = [UIBezierPath bezierPath];
    [line moveToPoint:_one];
    [line addLineToPoint:_two];
    [line stroke];
    
    [[self drawCircle] stroke];
}
#pragma mark-------------------画矩形--------------
- (UIBezierPath*)drawRectangle
{
    
    CGRect rect = CGRectMake(_one.x, _one.y, _two.x - _one.x, _two.y - _one.y);
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:rect];
    return path;
}
- (void)drawRectanglePath
{
    UIBezierPath* cir1 = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir1 fill];
    UIBezierPath* cir2 = [UIBezierPath bezierPathWithArcCenter:_two
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir2 fill];

    [[self drawRectangle] stroke];

}
#pragma mark-------------------画椭圆--------------
- (UIBezierPath*)drawOval
{
    
    CGFloat W = _two.x - _one.x;
    CGFloat H = _two.y - _one.y;
    CGRect rect = CGRectMake(_one.x - W, _one.y - H, 2 * W, 2 * H);
    
    UIBezierPath* path = [UIBezierPath bezierPathWithOvalInRect:rect];

    return path;
}
- (void)drawOvalPath
{
    
    CGFloat W = _two.x - _one.x;
    CGFloat H = _two.y - _one.y;
    CGRect rect = CGRectMake(_one.x - W, _one.y - H, 2 * W, 2 * H);
    UIBezierPath* cir1 = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir1 fill];
    UIBezierPath* cir2 = [UIBezierPath bezierPathWithArcCenter:_two
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir2 fill];
    
    UIBezierPath* quad = [UIBezierPath bezierPathWithRect:rect];
    [[UIColor lightGrayColor] setStroke];
    [quad stroke];

    [[self drawOval] stroke];

}
#pragma mark-------------------二次曲线------------
//二次曲线------移动
- (void)drawCuverTouchMove
{
    if (!_onDraw) {
        _two = _currentPoint;
        _three = CGPointMake((_one.x + _two.x) * 0.5, (_one.y + _two.y) * 0.5);
    }
    else {
        _one = _onOne ? _currentPoint : _one;
        _two = _onTwo ? _currentPoint : _two;
        _three = _onThree ? _currentPoint : _three;
    }
}
//二次曲线------
- (UIBezierPath*)drawCuver
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:_one];
    [path addQuadCurveToPoint:_two controlPoint:_three];
    return path;
}
//二次曲线------渲染
- (void)drawCuverPath
{
    UIBezierPath* cir1 = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir1 fill];
    UIBezierPath* cir2 = [UIBezierPath bezierPathWithArcCenter:_two
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir2 fill];
    UIBezierPath* cir3 = [UIBezierPath bezierPathWithArcCenter:_three
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir3 fill];
    
    [[self drawCuver] stroke];
}
#pragma mark-------------------三角形-------------
- (UIBezierPath*)drawTriangle
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:_one];
    [path addLineToPoint:_two];
    [path addLineToPoint:_three];
    [path closePath];
    return path;
}
- (void)drawTrianglePath
{
    UIBezierPath* cir1 = [UIBezierPath bezierPathWithArcCenter:_one
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir1 fill];
    UIBezierPath* cir2 = [UIBezierPath bezierPathWithArcCenter:_two
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir2 fill];
    UIBezierPath* cir3 = [UIBezierPath bezierPathWithArcCenter:_three
                                                        radius:5
                                                    startAngle:0
                                                      endAngle:2 * M_PI
                                                     clockwise:1];
    [cir3 fill];
    [[self drawTriangle] stroke];
}

//选择拖动点
- (BOOL)selectPoint:(CGPoint)Point OnPoint:(CGPoint)center
{
    CGRect rect = CGRectMake(center.x - 5, center.y - 5, 10, 10);
    return CGRectContainsPoint(rect, Point);
}

@end
