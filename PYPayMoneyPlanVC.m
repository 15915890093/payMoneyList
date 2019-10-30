//
//  PYPayMoneyPlanVC.m
//  PYFund
//
//  Created by 郭杰智 on 2019/6/18.
//  Copyright © 2019 PY. All rights reserved.
//

#import "PYPayMoneyPlanVC.h"
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "PYPayMoneyPlanHistoryVC.h"

#import "PYPayMoneyRecordCell.h"
#import "PYAddPayPlanVC.h"
#import "PYPayMoneyDetailVC.h"
#import "CALayer+Addition.h"

#import "PYSMPlanModel.h"

static NSString *payMoneyCellID = @"payMoneyCellID";

@interface PYPayMoneyPlanVC ()<UITableViewDelegate,UITableViewDataSource>
{
    UIActivityIndicatorView       *_indicatorView;
}

@property (nonatomic, strong) PYTableView *tableView;
@property (nonatomic, strong) UIView *saveHeadView;
@property (nonatomic, strong) UILabel *turnMoneyLb;
/** 本月未转出(元) */
@property (nonatomic, copy) NSString *totalMoney;
/** 用钱数组 */
@property (nonatomic, strong) NSMutableArray *tillList;

@property (nonatomic, strong) UIView *bgView;

// 自定义的导航栏
@property (nonatomic, strong) UIView *topView;

@property (nonatomic, strong) UIImageView     *navBgIV;

@property (nonatomic, strong) UIImage         *navBgImage;

@property (nonatomic, strong) UIToolbar *toolBar;

@end

@implementation PYPayMoneyPlanVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configTableView];
    [self configNavi];
    [self configBottomView];
    
    // 加载缓存
    [self loadCache];
    
    Async_Safe(^{
        if (EmptyArray(self.tillList)) {
            [_indicatorView startAnimating];
        }
        [self requestData];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestData) name:NotificationAlterPMPlanReload object:nil];
    });
}

- (void)configTableView {
    
    self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, -ScreenHeight, ScreenWidth, ScreenHeight + 115 + TopHeight)];
    [_bgView.layer addSublayer:[CAGradientLayer PYGradientLayerFrame:_bgView.bounds]];
    [self.view addSubview:_bgView];
    
    //获取导航条背景图
    self.navBgImage = [UIImage imageFromView:_bgView rect:CGRectMake(0, _bgView.py_height-TopHeight-115, _bgView.py_width, TopHeight)];
    
    _tableView = [[PYTableView alloc] initWithFrame:CGRectMake(0, TopHeight, ScreenWidth, ScreenHeight-TopHeight-(ISIPHONEX?104:80)) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = Color_BG;
    [_tableView registerClass:[PYPayMoneyRecordCell class] forCellReuseIdentifier:payMoneyCellID];
    [self.view addSubview:_tableView];
    
    self.saveHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 115)];
    self.saveHeadView.backgroundColor = [UIColor clearColor];
    _tableView.tableHeaderView = self.saveHeadView;
    
    UILabel *turnLb = [[UILabel alloc] init];
    turnLb.text = @"本月还需转出(元)";
    turnLb.textAlignment = NSTextAlignmentCenter;
    turnLb.font = [UIFont systemFontOfSize:15];
    turnLb.textColor = [UIColor whiteColor];
    [self.saveHeadView addSubview:turnLb];
    [turnLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.saveHeadView).with.offset(0);
        make.top.equalTo(self.saveHeadView).with.offset(28);
        make.size.mas_equalTo(CGSizeMake(200, 15));
    }];
    
    self.turnMoneyLb = [[UILabel alloc] init];
    
    if (!EmptyString(self.totalMoney)) {
        _turnMoneyLb.text = self.totalMoney;
    }else{
        _turnMoneyLb.text = @"0.00";
    }
    _turnMoneyLb.textAlignment = NSTextAlignmentCenter;
    _turnMoneyLb.font = [UIFont systemFontOfSize:27];
    _turnMoneyLb.textColor = [UIColor whiteColor];
    [self.saveHeadView addSubview:_turnMoneyLb];
    [self.turnMoneyLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.saveHeadView).with.offset(0);
        make.top.equalTo(turnLb.mas_bottom).with.offset(10);
        make.size.mas_equalTo(CGSizeMake(ScreenWidth, 27));
    }];
}

#pragma mark -- tableView delegate && dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tillList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PYPayMoneyRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:payMoneyCellID forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setModel:self.tillList[indexPath.section] type:0 ];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PYPayMoneyDetailVC *controller = [[PYPayMoneyDetailVC alloc] init];
    controller.model = self.tillList[indexPath.section];
    [self.navigationController pushViewController:controller animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 170;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

- (void)configNavi{
    self.fd_prefersNavigationBarHidden = YES;
    
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, TopHeight)];
    _topView.backgroundColor = [UIColor clearColor];
    self.navBgIV = [[UIImageView alloc] initWithFrame:self.topView.bounds];
    self.navBgIV.image = self.navBgImage;
    [_topView addSubview:self.navBgIV];
    
    [self.view addSubview:_topView];
    
    [self.topView addSubview:self.toolBar];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    
    self.bgView.frame = CGRectMake(0, -ScreenHeight - offsetY, ScreenWidth, ScreenHeight + 115 + TopHeight);
    
    self.navBgIV.hidden = offsetY>0? NO:YES;
    
    if (offsetY > 50) {
        CGFloat alpha = MIN(1, 1 - ((50 + TopHeight - offsetY) / 64));
        self.topView.backgroundColor = HexColor(@"#3356D9",alpha);
    } else {
        self.topView.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - Lazy load

- (UIToolbar *)toolBar {
    if (!_toolBar) {
        _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, StateHeight, ScreenWidth, 44)];
        _toolBar.tintColor = [UIColor whiteColor];
        [_toolBar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        [_toolBar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
        
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"py_back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:self
                                                                               action:nil];
        UIBarButtonItem *rightBarButtonItem = ({
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 56, 30)];
            [button setTitle:@"历史计划" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
            button.titleLabel.font = Font(14);
            button.titleLabel.minimumScaleFactor = 0.5;
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            button.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            [button addTarget:self action:@selector(historyList) forControlEvents:UIControlEventTouchUpInside];
            
            UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:button];
            rightItem;
        });
        
        NSArray *barItems = @[leftBarButtonItem,space,rightBarButtonItem];
        [_toolBar setItems:barItems];
        
        UILabel *titleLb = [[UILabel alloc] init];
        titleLb.textColor = [UIColor whiteColor];
        titleLb.textAlignment = NSTextAlignmentCenter;
        titleLb.font = Font(20);
        titleLb.text = @"用钱计划";
        [_toolBar addSubview:titleLb];
        [titleLb mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_toolBar);
            make.centerY.equalTo(_toolBar).with.offset(0);
            make.size.mas_equalTo(CGSizeMake(260, 20));
        }];
        [_toolBar addSubview:titleLb];
        
        CGSize size = PY_TEXTSIZE(titleLb.text, titleLb.font, CGSizeMake(260, 30), NSLineBreakByCharWrapping);

        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicatorView.frame = CGRectMake((ScreenWidth-size.width)/2.-29, 10, 24, 24);
        [_toolBar addSubview:_indicatorView];
    }
    return _toolBar;
}

- (void)configBottomView {
    CGFloat y = (ISIPHONEX? 44:20);
    
    UIButton *addSaveBtn = [[UIButton alloc] init];
    addSaveBtn.layer.cornerRadius = 3;
    addSaveBtn.clipsToBounds = YES;
    addSaveBtn.backgroundColor = Color_Main;
    [addSaveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [addSaveBtn setTitle:@"新增用钱计划" forState:UIControlStateNormal];
    addSaveBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:addSaveBtn];
    [addSaveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).with.offset(-y);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(ScreenWidth-40, 44));
    }];
    [addSaveBtn addTarget:self action:@selector(toAddPayPlan) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - 数据加载

- (void)loadCache {
    
    NSDictionary *cache = (NSDictionary *)[CacheTool loadFundHttpCache:PYFRequestType_yingmi_queryRedeemPlanList addUserId:YES];
    
    if (!EmptyDictionary(cache)) {
        NSString *money = [cache[@"data"] objectForKey:@"totalMoney" type:PYTypeString];
        if (!EmptyString(money)) {
            NSString *amount = [NSString stringToNumberFormat:[NSString stringWithFormat:@"%.2f",[money doubleValue]]];
            self.turnMoneyLb.text = amount;
        }
        
        NSArray *data = [cache[@"data"] objectForKey:@"list"];
        if (!EmptyArray(data)) {
            self.tillList = [PYSMPlanModel mj_objectArrayWithKeyValuesArray:data];
        }
    }
    
    if (!EmptyArray(_tillList)) {
        [self.tableView reloadData];
    }
}

- (void)requestData {
    [self hideErrorView];
    
    NSDictionary *param = @{@"type":@"0"};
    // 用钱计划列表查询
    [PYNetRequest postForFund:PYFRequestType_yingmi_queryRedeemPlanList params:param completed:^(NSDictionary *responseDic) {
        NSString *msg = nil;
        if ([PYNetRequest checkResponseDic:responseDic msg:&msg]) {
            
            NSString *money = [responseDic[@"data"] objectForKey:@"totalMoney" type:PYTypeString];
            if (!EmptyString(money)) {
                NSString *amount = [NSString stringToNumberFormat:[NSString stringWithFormat:@"%.2f",[money doubleValue]]];
                self.turnMoneyLb.text = amount;
            }
            
            NSArray *data = [responseDic[@"data"] objectForKey:@"list"];
            [self.tillList removeAllObjects];
            
            if (!EmptyArray(data)) {
                self.tillList = [PYSMPlanModel mj_objectArrayWithKeyValuesArray:data];
            }
            else{
                [self showErrorView:@"暂无计划" imageName:@"py_nodata"];
            }
            
            [_tableView reloadData];
            
            [CacheTool storeFundHttpCache:responseDic fRequest:PYFRequestType_yingmi_queryRedeemPlanList addUserId:YES];
        }
        else {
            if (EmptyArray(self.tillList)) {
                [self showErrorView:msg imageName:@"py_nodata"];
            }
            else {
                [app showToastView:msg];
            }
        }
        [_indicatorView stopAnimating];
    }];
}

- (void)historyList {
    PYPayMoneyPlanHistoryVC *vc = [[PYPayMoneyPlanHistoryVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)toAddPayPlan {
    PYAddPayPlanVC *vc = [[PYAddPayPlanVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)backForward:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showErrorView:(NSString *)msg imageName:(NSString *)imageName {
    
    [self.errorView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.errorView.hidden = NO;
    
    if (msg && msg.length > 0) {
        self.errorStr = msg;
    }else {
        self.errorStr = @"暂无计划";
    }
    
    UIButton *button = [[UIButton alloc] init];
    [button setTitleColor:Color_Description forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [self.errorView addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.errorView);
        make.centerX.equalTo(self.errorView);
        make.size.mas_offset(CGSizeMake(82, 71));
    }];
    
    UILabel *tipLb = [[UILabel alloc] init];
    tipLb.text = self.errorStr;
    tipLb.textAlignment = NSTextAlignmentCenter;
    tipLb.font = [UIFont systemFontOfSize:15];
    tipLb.textColor = Color_Content;
    [self.errorView addSubview:tipLb];
    [tipLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(button.mas_bottom).with.offset(16);
        make.centerX.equalTo(self.errorView);
        make.size.mas_offset(CGSizeMake(ScreenWidth, 15));
    }];
    
}

#pragma mark - scrollView + 下拉刷新

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y < -60 && !_indicatorView.animating) {
        [_indicatorView startAnimating];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            [self requestData];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
}

- (NSMutableArray *)tillList {
    if (!_tillList) {
        self.tillList = [NSMutableArray array];
    }
    return _tillList;
}

@end
