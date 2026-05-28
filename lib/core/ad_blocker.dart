import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Generates ContentBlocker rules for ad, tracker, and analytics blocking.
/// Uses a curated domain list covering major ad networks, trackers, analytics,
/// social widgets, and crypto miners.
class AdBlocker {
  static final AdBlocker _instance = AdBlocker._internal();
  factory AdBlocker() => _instance;
  AdBlocker._internal();

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Master blocklist of ad/tracker/analytics domains.
  static const List<String> _blockDomains = [
    // ── Google Ads & DoubleClick ──
    'pagead2.googlesyndication.com',
    'googleads.g.doubleclick.net',
    'ad.doubleclick.net',
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'googletagmanager.com',
    'googletagservices.com',
    'adservice.google.com',
    'pagead2.googlesyndication.com',
    'tpc.googlesyndication.com',
    'partner.googleadservices.com',
    'www.googleadservices.com',

    // ── Facebook/Meta Tracking ──
    'connect.facebook.net',
    'pixel.facebook.com',
    'an.facebook.com',
    'www.facebook.com/tr',
    'graph.facebook.com',

    // ── Analytics & Tracking ──
    'analytics.google.com',
    'www.google-analytics.com',
    'ssl.google-analytics.com',
    'stats.g.doubleclick.net',
    'mc.yandex.ru',
    'hotjar.com',
    'static.hotjar.com',
    'script.hotjar.com',
    'vars.hotjar.com',
    'clarity.ms',
    'www.clarity.ms',
    'bat.bing.com',
    'tracking.mixpanel.com',
    'api.mixpanel.com',
    'cdn.mxpnl.com',
    'cdn.amplitude.com',
    'api.amplitude.com',
    'heapanalytics.com',
    'cdn.heapanalytics.com',
    'fullstory.com',
    'rs.fullstory.com',
    'segment.io',
    'cdn.segment.com',
    'api.segment.io',

    // ── Major Ad Networks ──
    'ads.yahoo.com',
    'adtech.de',
    'adnxs.com',
    'ib.adnxs.com',
    'secure.adnxs.com',
    'ads.pubmatic.com',
    'gads.pubmatic.com',
    'ssp.pubmatic.com',
    'openx.net',
    'us-u.openx.net',
    'rtb.openx.net',
    'bidder.criteo.com',
    'sslwidget.criteo.com',
    'dis.criteo.com',
    'ads.criteo.com',
    'static.criteo.net',
    'rubiconproject.com',
    'fastlane.rubiconproject.com',
    'optimized-by.rubiconproject.com',
    'prebid.a]dpnxs.com',
    'contextweb.com',
    'taboola.com',
    'cdn.taboola.com',
    'trc.taboola.com',
    'nr.taboola.com',
    'outbrain.com',
    'widgets.outbrain.com',
    'log.outbrain.com',
    'odb.outbrain.com',
    'revcontentapi.com',
    'mgid.com',
    'jsc.mgid.com',

    // ── Tracking Pixels & Beacons ──
    'pixel.quantserve.com',
    'pixel.adsafeprotected.com',
    'sb.scorecardresearch.com',
    'b.scorecardresearch.com',
    'beacon.krxd.net',
    'cdn.krxd.net',
    'usermatch.krxd.net',
    'tags.bluekai.com',
    'stags.bluekai.com',
    'bkrtx.com',
    'idsync.rlcdn.com',
    'pippio.com',
    'w55c.net',
    'dpm.demdex.net',
    'cm.everesttech.net',
    'pixel.wp.com',
    'stats.wp.com',

    // ── Ad Servers ──
    'serving-sys.com',
    'bs.serving-sys.com',
    'cdn.flashtalking.com',
    'servedby.flashtalking.com',
    's0.2mdn.net',
    'z.moatads.com',
    'px.moatads.com',
    'js.moatads.com',
    'geo.moatads.com',
    'mb.moatads.com',
    'ad.turn.com',
    'r.turn.com',
    'mediaplex.com',
    'ads.linkedin.com',
    'snap.licdn.com',
    'px.ads.linkedin.com',
    'ad.atdmt.com',
    'view.atdmt.com',
    'clk.atdmt.com',

    // ── Social Widgets & Buttons ──
    'platform.twitter.com',
    'syndication.twitter.com',
    'static.ads-twitter.com',
    'analytics.twitter.com',
    'badges.pinterest.com',
    'widgets.pinterest.com',
    'log.pinterest.com',
    'trk.pinterest.com',
    'apis.google.com/js/plusone.js',

    // ── Pop-ups & Redirects ──
    'adf.ly',
    'shorte.st',
    'sh.st',
    'bc.vc',
    'gestyy.com',
    'linkvertise.com',
    'shrinkme.io',
    'exe.io',
    'fc.lc',
    'za.gl',

    // ── Crypto Miners ──
    'coinhive.com',
    'coin-hive.com',
    'jsecoin.com',
    'crypto-loot.com',
    'cryptaloot.pro',
    'authedmine.com',
    'ppoi.org',
    'projectpoi.com',
    'monerominer.rocks',
    'minero.cc',
    'webminepool.com',
    'coin-have.com',
    'afminer.com',
    'miner.pr0gramm.com',

    // ── Mobile Ad SDKs ──
    'app.appsflyer.com',
    'impressions.appsflyer.com',
    'onelink.appsflyer.com',
    'app-measurement.com',
    'firebase-settings.crashlytics.com',
    'settings.crashlytics.com',
    'e.crashlytics.com',
    'reports.crashlytics.com',
    'adjust.com',
    'app.adjust.com',
    'view.adjust.com',
    'branch.io',
    'api.branch.io',
    'cdn.branch.io',
    'bnc.lt',
    'kochava.com',
    'control.kochava.com',
    'tenjin.com',

    // ── Fingerprinting ──
    'cdn.jsdelivr.net/npm/fingerprintjs',
    'fp.dfrn.co',
    'api.fpjs.io',
    'fingerprint.com',
    'cdn.fingerprint.com',

    // ── Retargeting ──
    'ct.pinterest.com',
    'ads.pinterest.com',
    'adsapi.snapchat.com',
    'sc-static.net/scevent.min.js',
    'tr.snapchat.com',
    'ad.tiktok.com',
    'analytics.tiktok.com',
    'business-api.tiktok.com',
    'mon.byteoversea.com',
    'p16-tiktok-va.ibyteimg.com',

    // ── Other Common Trackers ──
    'smartadserver.com',
    'adroll.com',
    's.adroll.com',
    'd.adroll.com',
    'advertising.com',
    'pixel.advertising.com',
    'yieldmanager.com',
    'atwola.com',
    'adserver.yahoo.com',
    'vdna-content.com',
    'mathtag.com',
    'pixel.mathtag.com',
    'adadvisor.net',
    'addthis.com',
    's7.addthis.com',
    'm.addthisedge.com',
    'exelator.com',
    'loadm.exelator.com',
    'survey.surveymonkey.com',
    'conviva.com',
    'liveintent.com',
    'liadm.com',
    'ib.mookie1.com',
    'tags.tiqcdn.com',
    'c.amazon-adsystem.com',
    'aax.amazon-adsystem.com',
    'z-na.amazon-adsystem.com',
    'fls-na.amazon-adsystem.com',
    'mads.amazon-adsystem.com',
    'wms.assoc-amazon.com',
    'rcm-na.amazon-adsystem.com',
    's.amazon-adsystem.com',

    // ── CNAME Trackers ──
    'smetrics.com',
    'tr.hit.gemius.pl',
    'hit.gemius.pl',
    'gadasource.storage.googleapis.com',
  ];

  /// Build the ContentBlocker list for InAppWebView.
  List<ContentBlocker> getContentBlockers() {
    if (!_enabled) return [];

    final List<ContentBlocker> blockers = [];

    // Block each domain and its subdomains
    for (final domain in _blockDomains) {
      final escapedDomain = domain.replaceAll('.', '\\\\.');
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: '.*$escapedDomain.*',
            resourceType: [
              ContentBlockerTriggerResourceType.SCRIPT,
              ContentBlockerTriggerResourceType.IMAGE,
              ContentBlockerTriggerResourceType.STYLE_SHEET,
              ContentBlockerTriggerResourceType.RAW,
              ContentBlockerTriggerResourceType.FONT,
              ContentBlockerTriggerResourceType.SVG_DOCUMENT,
              ContentBlockerTriggerResourceType.MEDIA,
            ],
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }

    // CSS rules to hide common ad containers
    final adSelectors = [
      '.ad-banner',
      '.ad-container',
      '.ad-wrapper',
      '.ad-slot',
      '.ad-unit',
      '.ads-banner',
      '.adsbygoogle',
      '#ad-banner',
      '#ad-container',
      '#google_ads',
      '#taboola-below',
      '#taboola-above',
      '.outbrain-widget',
      '#outbrain_widget',
      '.sponsored-content',
      '.promoted-content',
      '[id^="google_ads"]',
      '[id^="div-gpt-ad"]',
      'ins.adsbygoogle',
      'iframe[src*="doubleclick"]',
      'iframe[src*="googlesyndication"]',
    ];

    blockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*',
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: adSelectors.join(', '),
        ),
      ),
    );

    return blockers;
  }

  /// Count of blocked domain patterns
  int get blockedDomainCount => _blockDomains.length;
}
