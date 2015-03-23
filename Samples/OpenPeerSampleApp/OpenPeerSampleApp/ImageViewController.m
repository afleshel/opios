/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

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
