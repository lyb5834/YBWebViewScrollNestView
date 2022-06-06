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
#import "MYTableView.h"

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
@property (nonatomic, strong) MYTableView * tableView;
@property (nonatomic, strong) NSMutableArray <TestModel *>* dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"首页";
    [self.view addSubview:self.nestView];
    
    [self.nestView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.bottomView.mas_top);
    }];
    
    NSString * urlPath = @"https://www.jianshu.com/p/2ov8x3";
    [self.webView loadRequest:[NSURLRequest requestWithURL:[self getUrlWithString:urlPath]]];
    
    [self dataInit];
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

#pragma mark - lazyloads
- (YBWebViewScrollNestView *)nestView
{
    if (!_nestView) {
        _nestView = [[YBWebViewScrollNestView alloc] initWithDelegate:self];
    }
    return _nestView;
}

- (MYTableView *)tableView
{
    if (!_tableView) {
        _tableView = [[MYTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
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
    
    [tableView beginUpdates];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [tableView endUpdates];
}

#pragma mark - YBWebViewScrollNestViewContainerDelegate
- (WKWebView *)webViewInContainer
{
    return self.webView;
}

- (UITableView<YBNestTableViewProtocol> *)tableViewInContainer
{
    return self.tableView;
}

@end
