//
//  ImageViewController.m
//  OpenPeerSampleApp
//
//  Created by Developer Developic on 3/20/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, weak) UIImage* image;
@property (nonatomic) float zoomFactor;

- (void) zoomImage:(UITapGestureRecognizer*) gesture;
@end

@implementation ImageViewController


- (id)initWithImage:(UIImage*) image
{
    self = [super initWithNibName:@"ImageViewController" bundle:nil];
    if (self)
    {
        if (image)
        {
            self.image = image;
            self.imageView = [[UIImageView alloc] initWithImage:image];
            self.imageView.userInteractionEnabled = YES;
            
            UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImage:)];
            if (gesture)
            {
                gesture.numberOfTapsRequired = 2;
                [self.imageView addGestureRecognizer:gesture];
            }
        }
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
 
    float minScale = self.imageScrollView.bounds.size.width/self.image.size.width;
    if (minScale >= 1.0)
        minScale = 1.0;
    
    float minScaleHeight = self.imageScrollView.bounds.size.height/self.image.size.height;
    minScale = minScale < minScaleHeight ? minScale : minScaleHeight;
    
    self.imageScrollView.contentSize = CGSizeMake(self.imageView.frame.size.width , self.imageView.frame.size.height);
    self.imageScrollView.maximumZoomScale = 1;
    self.imageScrollView.minimumZoomScale = minScale;
    self.imageScrollView.clipsToBounds = YES;
    self.imageScrollView.delegate = self;
    
    //CGSize scrollViewBoundsSize = self.imageScrollView.bounds.size;
//    CGFloat offsetX = MAX((self.imageScrollView.contentSize.width - self.imageScrollView.bounds.size.width) * 0.5, 0.0);
//    CGFloat offsetY = MAX((self.imageScrollView.contentSize.height - self.imageScrollView.bounds.size.height) * 0.5, 0.0);
    
    CGRect  rect = self.imageView.frame;
    rect.origin.x = (self.imageScrollView.bounds.size.width - self.image.size.width*minScale)/2.0;
    rect.origin.y = (self.imageScrollView.bounds.size.height - self.image.size.height*minScale)/2.0;
    self.imageView.frame = rect;
//    self.imageView.center = CGPointMake(offsetX, offsetY);//CGPointMake(self.imageScrollView.contentSize.width * 0.25 + offsetX, self.imageScrollView.contentSize.height * 0.25 + offsetY);
    
    //[self.imageScrollView setContentOffset:CGPointMake(offsetX, offsetY)];
    
    [self.imageScrollView addSubview:self.imageView];
    self.imageScrollView.zoomScale = minScale;
    self.zoomFactor = minScale;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)inScroll
{
    return self.imageView;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) zoomImage:(UITapGestureRecognizer*) gesture
{
    if (self.zoomFactor == self.imageScrollView.minimumZoomScale)
    {
        self.zoomFactor = self.imageScrollView.maximumZoomScale;
        self.imageScrollView.zoomScale = self.zoomFactor;
    }
    else
    {
        self.zoomFactor = self.imageScrollView.minimumZoomScale;
        self.imageScrollView.zoomScale = self.zoomFactor;
    }
}
@end
