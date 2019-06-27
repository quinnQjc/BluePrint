//
//  CtrlViewController.m
//  GSDK
//
//  Created by 猿史森林 on 2018/6/16.
//  Copyright © 2018年 Smarnet. All rights reserved.
//

#import "CtrlViewController.h"
#import "ConnecterManager.h"
#import "EscCommand.h"
#import "TscCommand.h"
#import "BluetoothListViewController.h"

@interface CtrlViewController (){
    BOOL isReceive;
}
@property (strong, nonatomic) IBOutlet UITextField *ipTextField;
@property (strong, nonatomic) IBOutlet UITextField *portTextField;
@property (strong, nonatomic) IBOutlet UILabel *connState;
@end

@implementation CtrlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *url = [NSURL URLWithString:@"https://baidu.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setTimeoutInterval:10];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  断开连接
 */
- (IBAction)disconnectAction:(id)sender {
    [Manager close];
}


- (IBAction)hideKeyboardAction:(id)sender {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (IBAction)bleConnAction:(id)sender {
    BluetoothListViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    viewController.state = ^(ConnectState state) {
        [self updateConnectState:state];
    };
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)labelPrintAction:(id)sender {
    [Manager write:[self tscCommand]];
}

-(NSData *)tscCommand{
    TscCommand *command = [[TscCommand alloc]init];
    [command addSize:48 :80];
    [command addGapWithM:2 withN:0];
    [command addReference:0 :0];
    [command addTear:@"ON"];
    [command addQueryPrinterStatus:ON];
    [command addCls];
    [command addTextwithX:0 withY:0 withFont:@"TSS24.BF2" withRotation:0 withXscal:1 withYscal:1 withText:@"Smarnet"];
    [command add1DBarcode:30 :30 :@"CODE128" :100 :1 :0 :2 :2 :@"1234567890"];
    [command addQRCode:20 :160 :@"L" :5 :@"A" :0 :@"www.smarnet.cc"];
    UIImage *image = [UIImage imageNamed:@"gprinter.png"];
    [command addBitmapwithX:0 withY:260 withMode:0 withWidth:400 withImage:image];
    [command addPrint:1 :1];
    return [command getCommand];
}

- (IBAction)writeAndRead:(id)sender {
    //发送标签模式查询
    unsigned char tscCommand[] = {0x1B, 0x21, 0x3F};
    NSData *data = [NSData dataWithBytes:tscCommand length:sizeof(tscCommand)];
    isReceive = NO;
    Manager.connecter.readData = ^(NSData * _Nullable data) {
        isReceive = YES;
        NSLog(@"data -> %@",data);
    };
    [Manager write:data];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!isReceive) {
            //esc查询状态指令
            unsigned char escCommand[] = {0x1D,0x72,0x01};
            [Manager write:[NSData dataWithBytes:escCommand length:sizeof(escCommand)]];
        }
    });
}

//只适用于蓝牙连接
- (IBAction)progressWriteLabel:(id)sender {
    [Manager write:[self tscCommand] progress:^(NSUInteger total, NSUInteger progress) {
        CGFloat p = (CGFloat)progress / (CGFloat)total;
//        [SVProgressHUD showProgress:p status:@"发送中..."];
    } receCallBack:^(NSData * _Nullable data) {
//        [SVProgressHUD dismiss];
    }];
}

//只适用于蓝牙连接
- (IBAction)progressWriteTicket:(id)sender {
    [Manager write:[self escCommand] progress:^(NSUInteger total, NSUInteger progress) {
        CGFloat p = (CGFloat)progress / (CGFloat)total;
//        [SVProgressHUD showProgress:p status:@"发送中..."];
    } receCallBack:^(NSData * _Nullable data) {
//        [SVProgressHUD dismiss];
    }];
}

- (IBAction)ticketPrintAction:(id)sender {
    
    [Manager write:[self escCommand]];
}

-(NSData *)escCommand{
    EscCommand *command = [[EscCommand alloc]init];
    [command addInitializePrinter];
    [command addPrintAndFeedLines:5];
    //内容居中
    [command addSetJustification:1];
    [command addPrintMode: 0|8|16|32];
    [command addText:@"Print text\n"];
    [command addPrintAndLineFeed];
    [command addPrintMode: 0];
    [command addText:@"Welcome to use Smarnet printer!"];
    //换行
    [command addPrintAndLineFeed];
    //内容居左（默认居左）
    [command addSetJustification:0];
    [command addText:@"智汇"];
    //设置水平和垂直单位距离
    [command addSetHorAndVerMotionUnitsX:7 Y:0];
    //设置绝对位置
    [command addSetAbsolutePrintPosition:6];
    [command addText:@"网络"];
    [command addSetAbsolutePrintPosition:10];
    [command addText:@"设备"];
    [command addPrintAndLineFeed];
    NSString *content = @"Gprinter";
    //二维码
    [command addQRCodeSizewithpL:0 withpH:0 withcn:0 withyfn:0 withn:5];
    [command addQRCodeSavewithpL:0x0b withpH:0 withcn:0x31 withyfn:0x50 withm:0x30 withData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [command addQRCodePrintwithpL:0 withpH:0 withcn:0 withyfn:0 withm:0];
    [command addPrintAndLineFeed];

    [command addSetBarcodeWidth:2];
    [command addSetBarcodeHeight:60];
    [command addSetBarcodeHRPosition:2];
    [command addCODE128:'B' : @"ABC1234567890"];
    
    [command addPrintAndLineFeed];
    
    UIImage *image = [UIImage imageNamed:@"gprinter.png"];
    [command addOriginrastBitImage:image];
    [command addPrintAndFeedLines:5];
    return [command getCommand];
}

/**
 *  连接
 */
- (IBAction)connectAction:(id)sender {
    NSString *ip = self.ipTextField.text;
    int port = [self.portTextField.text intValue];
    [Manager connectIP:ip port:port connectState:^(ConnectState state) {
        [self updateConnectState:state];
    } callback:^(NSData *data) {
        
    }];
}

-(void)updateConnectState:(ConnectState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (state) {
            case CONNECT_STATE_CONNECTING:
                self.connState.text = @"连接状态：连接中....";
                break;
            case CONNECT_STATE_CONNECTED:
//                [SVProgressHUD showSuccessWithStatus:@"连接成功"];
                self.connState.text = @"连接状态：已连接";
                break;
            case CONNECT_STATE_FAILT:
//                [SVProgressHUD showErrorWithStatus:@"连接失败"];
                self.connState.text = @"连接状态：连接失败";
                break;
            case CONNECT_STATE_DISCONNECT:
//                [SVProgressHUD showInfoWithStatus:@"断开连接"];
                self.connState.text = @"连接状态：断开连接";
                break;
            default:
                self.connState.text = @"连接状态：连接超时";
                break;
        }
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
