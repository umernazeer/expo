
#import <ABI34_0_0EXAdsFacebook/ABI34_0_0EXFacebookAdHelper.h>
#import <ABI34_0_0EXAdsFacebook/ABI34_0_0EXNativeAdManager.h>
#import <ABI34_0_0EXAdsFacebook/ABI34_0_0EXNativeAdView.h>

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <ABI34_0_0UMCore/ABI34_0_0UMUtilities.h>
#import <ABI34_0_0UMCore/ABI34_0_0UMUIManager.h>
#import <ABI34_0_0UMCore/ABI34_0_0UMEventEmitterService.h>

@interface ABI34_0_0EXNativeAdManager () <FBNativeAdsManagerDelegate>

@property (nonatomic, weak) ABI34_0_0UMModuleRegistry *moduleRegistry;
@property (nonatomic, strong) NSMutableDictionary<NSString*, FBNativeAdsManager*> *adsManagers;

@end

@implementation ABI34_0_0EXNativeAdManager

ABI34_0_0UM_EXPORT_MODULE(CTKNativeAdManager)

- (instancetype)init
{
  self = [super init];
  if (self) {
    _adsManagers = [NSMutableDictionary new];
  }
  return self;
}

- (NSString *)viewName
{
  return @"CTKNativeAd";
}

- (void)setModuleRegistry:(ABI34_0_0UMModuleRegistry *)moduleRegistry
{
  _moduleRegistry = moduleRegistry;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"CTKNativeAdsManagersChanged", @"onAdLoaded"];
}

ABI34_0_0UM_EXPORT_METHOD_AS(registerViewsForInteraction,
                    registerViewsForInteraction:(NSNumber *)nativeAdViewTag
                    mediaViewTag:(NSNumber *)mediaViewTag
                    adIconViewTag:(NSNumber *)adIconViewTag
                    clickableViewsTags:(NSArray *)tags
                    resolve:(ABI34_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI34_0_0UMPromiseRejectBlock)reject)
{
  id<ABI34_0_0UMUIManager> uiManager = [_moduleRegistry getModuleImplementingProtocol:@protocol(ABI34_0_0UMUIManager)];
  [uiManager executeUIBlock:^(NSDictionary<id,UIView *> * viewRegistry) {
    UIView *mediaView = nil;
    UIView *adIconView = nil;
    UIView *nativeAdView = nil;
    NSMutableArray<UIView *> *clickableViews = [NSMutableArray new];

    mediaView = viewRegistry[mediaViewTag];
    adIconView = viewRegistry[adIconViewTag];
    nativeAdView = viewRegistry[nativeAdViewTag];
    for (id tag in tags) {
      if (viewRegistry[tag]) {
        [clickableViews addObject:viewRegistry[tag]];
      } else {
        clickableViews = nil;
        break;
      }
    }

    if (!clickableViews) {
      reject(@"E_INVALID_VIEW_TAG", @"Could not find view for one of the clickable views tags", nil);
      return;
    }

    if (mediaView == nil) {
      reject(@"E_NO_VIEW_FOR_TAG", @"Could not find mediaView", nil);
      return;
    }

    if (nativeAdView == nil) {
      reject(@"E_NO_NATIVEAD_VIEW", @"Could not find nativeAdView", nil);
      return;
    }

    if (![mediaView isKindOfClass:[FBMediaView class]]) {
      reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed media view tag is not an instance of FBMediaView", nil);
      return;
    }

    if (![nativeAdView isKindOfClass:[ABI34_0_0EXNativeAdView class]]) {
      reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed native ad view tag is not an instance of ABI34_0_0EXNativeAdView", nil);
      return;
    }

    if (adIconView) {
      if (![adIconView isKindOfClass:[FBMediaView class]]) {
        reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed ad icon view tag is not an instance of FBMediaView", nil);
        return;
      }
    }

    [(ABI34_0_0EXNativeAdView *)nativeAdView registerViewsForInteraction:(FBMediaView *)mediaView adIcon:(FBMediaView *)adIconView clickableViews:clickableViews];
    resolve(@[]);
  }];
}

ABI34_0_0UM_EXPORT_METHOD_AS(init,
                    init:(NSString *)placementId
                    withAdsToRequest:(NSNumber *)adsToRequest
                    resolve:(ABI34_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI34_0_0UMPromiseRejectBlock)reject)
{
  if (![ABI34_0_0EXFacebookAdHelper facebookAppIdFromNSBundle]) {
    ABI34_0_0UMLogWarn(@"No Facebook app id is specified. Facebook ads may have undefined behavior.");
  }
  FBNativeAdsManager *adsManager = [[FBNativeAdsManager alloc] initWithPlacementID:placementId
                                                                forNumAdsRequested:[adsToRequest intValue]];

  [adsManager setDelegate:self];

  [ABI34_0_0UMUtilities performSynchronouslyOnMainThread:^{
    [adsManager loadAds];
  }];

  [_adsManagers setValue:adsManager forKey:placementId];
  resolve(nil);
}

ABI34_0_0UM_EXPORT_METHOD_AS(setMediaCachePolicy,
                    setMediaCachePolicy:(NSString *)placementId
                    cachePolicy:(NSString *)cachePolicy
                    resolve:(ABI34_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI34_0_0UMPromiseRejectBlock)reject)
{
  FBNativeAdsCachePolicy policy = [@{
                                     @"none": @(FBNativeAdsCachePolicyNone),
                                     @"all": @(FBNativeAdsCachePolicyAll),
                                     }[cachePolicy] integerValue] ?: FBNativeAdsCachePolicyNone;
  [_adsManagers[placementId] setMediaCachePolicy:policy];
  resolve(nil);
}

ABI34_0_0UM_EXPORT_METHOD_AS(disableAutoRefresh,
                    disableAutoRefresh:(NSString*)placementId
                    resolve:(ABI34_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI34_0_0UMPromiseRejectBlock)reject)
{
  [_adsManagers[placementId] disableAutoRefresh];
  resolve(nil);
}

- (void)nativeAdsLoaded
{
  NSMutableDictionary<NSString*, NSNumber*> *adsManagersState = [NSMutableDictionary new];

  [_adsManagers enumerateKeysAndObjectsUsingBlock:^(NSString* key, FBNativeAdsManager* adManager, __unused BOOL* stop) {
    [adsManagersState setValue:@([adManager isValid]) forKey:key];
  }];

  [[_moduleRegistry getModuleImplementingProtocol:@protocol(ABI34_0_0UMEventEmitterService)] sendEventWithName:@"CTKNativeAdsManagersChanged" body:adsManagersState];
}

- (void)nativeAdsFailedToLoadWithError:(NSError *)errors
{
  // @todo handle errors here
}

- (UIView *)view
{
  return [[ABI34_0_0EXNativeAdView alloc] initWithModuleRegistry:_moduleRegistry];
}

ABI34_0_0UM_VIEW_PROPERTY(adsManager, NSString *, ABI34_0_0EXNativeAdView)
{
  [view setNativeAd:[_adsManagers[value] nextNativeAd]];
}

- (void)startObserving {
}

- (void)stopObserving {
}

@end
