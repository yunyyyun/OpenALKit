//
//  ViewController.m
//  OpenAlDemo
//
//  Created by mengyun on 2018/6/22.
//  Copyright © 2018年 mengyun. All rights reserved.
//

#import "ViewController.h"
#import "OpenAL/OpenALPlayer.h"

@interface ViewController ()
- (IBAction)playSound:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)playSound:(id)sender {
    UIButton *button = (UIButton* )sender;
    int32_t tag = (int32_t)button.tag;
    [[OpenALPlayer shared] doPlayWithTag:tag];
}
@end
