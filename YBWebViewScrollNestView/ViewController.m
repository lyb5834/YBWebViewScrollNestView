//
//  ViewController.m
//  YBWebViewScrollNestView
//
//  Created by liyuanbo on 2022/5/26.
//

#import "ViewController.h"
#import "YBWebViewScrollNestView.h"
#import "MJRefresh.h"
#import "Masonry.h"
#import "TestModel.h"

@interface ViewController ()
<
YBWebViewScrollNestViewContainerDelegate,
UITableViewDelegate,
UITableViewDataSource,
WKUIDelegate,
WKNavigationDelegate
>

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic, strong) YBWebViewScrollNestView * nestView;
@property (nonatomic, strong) WKWebView * webView;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray <TestModel *>* dataArray;
@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"首页";
    [self.view addSubview:self.nestView];
    
    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self.nestView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.bottomView.mas_top);
    }];
    
    NSString * urlPath = @"https://article.xuexi.cn/articles/index.html?art_id=16839459196239307151&source=share&study_style_id=feeds_opaque&reco_id=101c0b0a2412c0a88442000j&share_to=copylink&study_share_enable=1&study_comment_disable=1&ptype=0&item_id=16839459196239307151";
    [self.webView loadRequest:[NSURLRequest requestWithURL:[self getUrlWithString:urlPath]]];
    
    [self dataInit];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)dataInit
{
    for (int i = 0; i < 5; i++) {
        TestModel * model = [TestModel new];
        model.title = [NSString stringWithFormat:@"这是第 %d 行,点击可展开收起",i + 1];
        model.isCellDeveloped = NO;
        [self.dataArray addObject:model];
    }
    [self.tableView reloadData];
}

- (void)addMoreData
{
    NSInteger count = self.dataArray.count;
    for (NSInteger i = count; i < count + 5; i++) {
        TestModel * model = [TestModel new];
        model.title = [NSString stringWithFormat:@"这是第 %ld 行,点击可展开收起",i + 1];
        model.isCellDeveloped = NO;
        [self.dataArray addObject:model];
    }
    
    //模拟延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.tableView.mj_footer endRefreshing];
    });
}

- (NSURL *)getUrlWithString:(NSString *)urlString
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    return [NSURL URLWithString:(NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL,kCFStringEncodingUTF8))];
#pragma clang diagnostic pop
}

- (void)onRightAction:(UIButton *)button
{
    if ([button.currentTitle isEqualToString:@"显示评论"]) {
        [button setTitle:@"回到顶部" forState:UIControlStateNormal];
        [self.nestView scrollToTableViewAnimated:YES];
    }else {
        [button setTitle:@"显示评论" forState:UIControlStateNormal];
        [self.nestView scrollToTopAnimated:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        double estimatedProgress = [change[NSKeyValueChangeNewKey] doubleValue];
        if (estimatedProgress == 1) {
            self.rightButton.enabled = YES;
        }
    }
}

#pragma mark - lazyloads
- (YBWebViewScrollNestView *)nestView
{
    if (!_nestView) {
        _nestView = [[YBWebViewScrollNestView alloc] initWithDelegate:self];
    }
    return _nestView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        __weak typeof(self) weakSelf = self;
        _tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
            __strong typeof(weakSelf)self = weakSelf;
            [self addMoreData];
        }];
    }
    return _tableView;
}

- (WKWebView *)webView
{
    if (!_webView) {
        WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *wkUController = [WKUserContentController new];
        
        webConfig.userContentController = wkUController;
        webConfig.allowsInlineMediaPlayback = YES;
        WKPreferences *preferences = [WKPreferences new];
        preferences.javaScriptEnabled = YES; // 默认认为YES
        preferences.javaScriptCanOpenWindowsAutomatically = YES; //
        
        webConfig.preferences = preferences;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero  configuration:webConfig];
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.allowsBackForwardNavigationGestures = YES;
        _webView.scrollView.bounces = YES;
        _webView.scrollView.bouncesZoom = YES;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.scrollView.showsVerticalScrollIndicator = NO;
        _webView.scrollView.directionalLockEnabled = YES;
        _webView.scrollView.delegate = self;
        [_webView setAllowsLinkPreview:false];
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
    return _webView;
}

- (NSMutableArray<TestModel *> *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(0, 0, 60, 44);
        [_rightButton setTitle:@"显示评论" forState:UIControlStateNormal];
        [_rightButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(onRightAction:) forControlEvents:UIControlEventTouchUpInside];
        _rightButton.enabled = NO;
    }
    return _rightButton;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identifier = @"cellID";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.backgroundColor = [UIColor yellowColor];
    }
    TestModel * model = self.dataArray[indexPath.row];
    cell.textLabel.text = model.title;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TestModel * model = self.dataArray[indexPath.row];
    return model.isCellDeveloped ? 88 : 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TestModel * model = self.dataArray[indexPath.row];
    model.isCellDeveloped = !model.isCellDeveloped;
    
    if (!tableView.mj_footer.isRefreshing) {
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }
}

#pragma mark - YBWebViewScrollNestViewContainerDelegate
- (WKWebView *)webViewInContainer
{
    return self.webView;
}

- (UITableView *)tableViewInContainer
{
    return self.tableView;
}

@end
