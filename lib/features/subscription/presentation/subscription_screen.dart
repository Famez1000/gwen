import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/state/app_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../chat/presentation/chat_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static final Uri _termsUrl = Uri.parse(
    'https://mlmasters.com/TermsAndConditions_Gwen.html',
  );
  static Set<String> get _productIds => _productIdByPlan.values.toSet();
  static Map<_SubscriptionPlan, String> get _productIdByPlan {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const {
        _SubscriptionPlan.monthly: 'GWEN_MONTHLY',
        _SubscriptionPlan.yearly: 'GWEN_YEARLY',
      };
    }

    return const {
      _SubscriptionPlan.monthly: 'gwen_monthly',
      _SubscriptionPlan.yearly: 'gwen_yearly',
    };
  }

  static const Map<_SubscriptionPlan, List<String>> _preferredTrialMarkers = {
    _SubscriptionPlan.monthly: [
      'gwen-monthly-trial',
      'gwen_monthly_trial',
      'monthly-trial',
      'monthly_trial',
    ],
    _SubscriptionPlan.yearly: [
      'gwen-yearly-trial',
      'gwen_yearly_trial',
      'yearly-trial',
      'yearly_trial',
    ],
  };
  static const bool _showSubscriptionDebug = bool.fromEnvironment(
    'SHOW_SUBSCRIPTION_DEBUG',
    defaultValue: true,
  );

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  Timer? _purchaseFlowTimeout;
  _SubscriptionPlan _selectedPlan = _SubscriptionPlan.yearly;
  Map<String, List<ProductDetails>> _productsById = {};
  List<String> _debugLines = [];
  bool _isStoreAvailable = false;
  bool _isLoadingProducts = true;
  bool _isPurchasePending = false;
  bool _didRequestInitialRestore = false;
  bool _openChatAfterNextPurchaseUpdate = false;
  String? _storeMessage;

  String get _storeName {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'App Store'
        : 'Google Play';
  }

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _addDebugLine('purchaseStream error: $error');
        if (!mounted) return;
        setState(() {
          _isPurchasePending = false;
          _storeMessage = 'Purchase update failed. Please try again.';
        });
      },
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _purchaseFlowTimeout?.cancel();
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    _addDebugLine('Loading products: ${_productIds.join(', ')}');
    setState(() {
      _isLoadingProducts = true;
      _storeMessage = null;
    });

    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      _addDebugLine('Billing available: $isAvailable');
      if (!mounted) return;

      if (!isAvailable) {
        setState(() {
          _isStoreAvailable = false;
          _isLoadingProducts = false;
          _productsById = {};
          _storeMessage = '$_storeName billing is not available right now.';
        });
        return;
      }

      final response = await _inAppPurchase.queryProductDetails(_productIds);
      _addDebugLine(
        'queryProductDetails returned ${response.productDetails.length} products, '
        'missing=${response.notFoundIDs.join(', ')}',
      );
      if (response.error != null) {
        _addDebugLine('queryProductDetails error: ${response.error!.message}');
      }
      if (!mounted) return;

      final productsById = <String, List<ProductDetails>>{};
      for (final product in response.productDetails) {
        productsById.putIfAbsent(product.id, () => []).add(product);
        _addDebugLine(_describeProduct(product));
      }
      final missingIds = response.notFoundIDs;
      final errorMessage = response.error?.message;

      setState(() {
        _isStoreAvailable = true;
        _isLoadingProducts = false;
        _productsById = productsById;
        if (errorMessage != null) {
          _storeMessage = errorMessage;
        } else if (missingIds.isNotEmpty) {
          _storeMessage =
              'Missing products in $_storeName: ${missingIds.join(', ')}';
        } else if (productsById.isEmpty) {
          _storeMessage =
              'No subscription products were returned by $_storeName.';
        } else {
          _storeMessage = null;
        }
      });

      await _restoreExistingSubscriptionIfNeeded(silent: true);
    } on PlatformException catch (error) {
      _addDebugLine(
        'loadProducts platform exception: code=${error.code}, '
        'message=${error.message}, details=${error.details}',
      );
      if (!mounted) return;
      setState(() {
        _isStoreAvailable = false;
        _isLoadingProducts = false;
        _productsById = {};
        _storeMessage =
            error.message ??
            'Could not load subscriptions from $_storeName. Please try again.';
      });
    } catch (error) {
      _addDebugLine('loadProducts exception: $error');
      if (!mounted) return;
      setState(() {
        _isStoreAvailable = false;
        _isLoadingProducts = false;
        _productsById = {};
        _storeMessage =
            'Could not load subscriptions from $_storeName. Please try again.';
      });
    }
  }

  Future<void> _restoreExistingSubscriptionIfNeeded({
    required bool silent,
  }) async {
    if (_didRequestInitialRestore ||
        context.read<AppState>().hasActiveSubscription) {
      _addDebugLine(
        'Skipping initial restore. didRequest=$_didRequestInitialRestore, '
        'hasActive=${context.read<AppState>().hasActiveSubscription}',
      );
      return;
    }

    _didRequestInitialRestore = true;
    try {
      _addDebugLine('Requesting ${silent ? 'silent' : 'manual'} restore.');
      await _inAppPurchase.restorePurchases();
    } catch (error) {
      _addDebugLine('restore exception: $error');
      if (!mounted || silent) return;
      setState(() {
        _storeMessage =
            'Could not check previous purchases. Please try restore.';
      });
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (!_productIds.contains(purchaseDetails.productID)) continue;
      _addDebugLine(
        'purchase update: product=${purchaseDetails.productID}, '
        'status=${purchaseDetails.status.name}, '
        'pendingComplete=${purchaseDetails.pendingCompletePurchase}, '
        'purchaseId=${purchaseDetails.purchaseID ?? 'null'}',
      );

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _purchaseFlowTimeout?.cancel();
          if (mounted) {
            setState(() {
              _isPurchasePending = true;
              _storeMessage = 'Waiting for $_storeName to finish the purchase.';
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchaseFlowTimeout?.cancel();
          await context.read<AppState>().activateStoreSubscription();
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          if (!mounted) return;
          setState(() {
            _isPurchasePending = false;
            _storeMessage = _openChatAfterNextPurchaseUpdate
                ? null
                : 'Gwen Plus is active.';
          });
          if (_openChatAfterNextPurchaseUpdate) {
            _openChatAfterNextPurchaseUpdate = false;
            await _openChatAfterPurchase();
          }
          break;
        case PurchaseStatus.error:
          _purchaseFlowTimeout?.cancel();
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          final errorMessage = purchaseDetails.error?.message;
          _addDebugLine('purchase error: ${errorMessage ?? 'unknown'}');
          if (_looksLikeAlreadySubscribed(errorMessage)) {
            await _restorePurchase();
            return;
          }
          if (mounted) {
            setState(() {
              _isPurchasePending = false;
              _storeMessage = errorMessage ?? 'The purchase failed.';
            });
          }
          break;
        case PurchaseStatus.canceled:
          _purchaseFlowTimeout?.cancel();
          if (mounted) {
            setState(() {
              _isPurchasePending = false;
              _storeMessage = 'Purchase cancelled.';
            });
          }
          break;
      }
    }
  }

  Future<void> _buySelectedPlan() async {
    if (_isLoadingProducts || _isPurchasePending) return;

    final product = _preferredProductForPlan(_selectedPlan);
    _addDebugLine(
      'Buy tapped: plan=${_selectedPlan.name}, '
      'selected=${product == null ? 'null' : _describeProduct(product)}',
    );
    if (!_isStoreAvailable || product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription is not available yet.')),
      );
      await _loadProducts();
      return;
    }

    setState(() {
      _isPurchasePending = true;
      _openChatAfterNextPurchaseUpdate = true;
      _storeMessage = null;
    });

    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: _purchaseParamForProduct(product),
      );
      _addDebugLine('buyNonConsumable started: $started');
      if (!started && mounted) {
        setState(() {
          _isPurchasePending = false;
          _openChatAfterNextPurchaseUpdate = false;
          _storeMessage = 'Could not start the purchase flow.';
        });
      } else if (started) {
        _startPurchaseFlowTimeout();
      }
    } on PlatformException catch (error) {
      _addDebugLine(
        'buy platform exception: code=${error.code}, '
        'message=${error.message}, details=${error.details}',
      );
      if (!mounted) return;
      setState(() {
        _isPurchasePending = false;
        _openChatAfterNextPurchaseUpdate = false;
        _storeMessage = error.message ?? 'Could not start the purchase flow.';
      });
    } catch (error) {
      _addDebugLine('buy exception: $error');
      if (!mounted) return;
      setState(() {
        _isPurchasePending = false;
        _openChatAfterNextPurchaseUpdate = false;
        _storeMessage = 'Could not start the purchase flow.';
      });
    }
  }

  void _startPurchaseFlowTimeout() {
    _purchaseFlowTimeout?.cancel();
    _purchaseFlowTimeout = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isPurchasePending) return;

      _addDebugLine('Purchase flow timeout: re-enabling button.');
      setState(() {
        _isPurchasePending = false;
        _openChatAfterNextPurchaseUpdate = false;
        _storeMessage = null;
      });
    });
  }

  bool _looksLikeAlreadySubscribed(String? message) {
    final normalized = message?.toLowerCase() ?? '';
    return normalized.contains('already') &&
        (normalized.contains('subscribed') ||
            normalized.contains('own') ||
            normalized.contains('purchased'));
  }

  Future<void> _openTerms() async {
    final launched = await launchUrl(
      _termsUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Terms and Conditions.')),
      );
    }
  }

  Future<void> _restorePurchase() async {
    if (_isPurchasePending) return;

    setState(() {
      _isPurchasePending = true;
      _openChatAfterNextPurchaseUpdate = false;
      _storeMessage = 'Checking $_storeName for previous purchases...';
    });

    try {
      _addDebugLine('Manual restore tapped.');
      await _inAppPurchase.restorePurchases();
      if (!mounted) return;
      setState(() {
        _isPurchasePending = false;
        _storeMessage =
            'Restore request sent. $_storeName will return any active purchase.';
      });
    } catch (error) {
      _addDebugLine('manual restore exception: $error');
      if (!mounted) return;
      setState(() {
        _isPurchasePending = false;
        _storeMessage = 'Could not restore purchases. Please try again.';
      });
    }
  }

  Future<void> _skipForTesting() async {
    final appState = context.read<AppState>();
    await appState.activateDebugSubscription();
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(appState: appState)),
    );
  }

  Future<void> _openChatAfterPurchase() async {
    final appState = context.read<AppState>();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(appState: appState)),
    );
  }

  String _priceForPlan(_SubscriptionPlan plan) {
    final product = _preferredProductForPlan(plan);
    return _paidPriceForProduct(product) ?? product?.price ?? plan.price;
  }

  String _subtitleForPlan(_SubscriptionPlan plan) {
    final product = _preferredProductForPlan(plan);

    if (_hasFreeTrial(product)) {
      return '3 days free trial period';
    }

    return plan.periodLabel;
  }

  ProductDetails? _preferredProductForPlan(_SubscriptionPlan plan) {
    final productId = _productIdByPlan[plan]!;
    final products = _productsById[productId];
    if (products == null || products.isEmpty) return null;

    final scoredProducts = [...products]
      ..sort((a, b) {
        return _offerScore(b, plan).compareTo(_offerScore(a, plan));
      });

    return scoredProducts.first;
  }

  PurchaseParam _purchaseParamForProduct(ProductDetails product) {
    if (product is GooglePlayProductDetails) {
      _addDebugLine(
        'Creating GooglePlayPurchaseParam with offerToken=${_shortToken(product.offerToken)}',
      );
      return GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
      );
    }

    return PurchaseParam(productDetails: product);
  }

  bool _hasFreeTrial(ProductDetails? product) {
    final offer = _subscriptionOfferForProduct(product);
    return offer?.pricingPhases.any((phase) => phase.priceAmountMicros == 0) ??
        false;
  }

  String? _paidPriceForProduct(ProductDetails? product) {
    final offer = _subscriptionOfferForProduct(product);
    final paidPhase = offer?.pricingPhases
        .where((phase) => phase.priceAmountMicros > 0)
        .firstOrNull;

    return paidPhase?.formattedPrice;
  }

  SubscriptionOfferDetailsWrapper? _subscriptionOfferForProduct(
    ProductDetails? product,
  ) {
    if (product is! GooglePlayProductDetails) return null;

    final subscriptionIndex = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (subscriptionIndex == null ||
        offers == null ||
        subscriptionIndex >= offers.length) {
      return null;
    }

    return offers[subscriptionIndex];
  }

  int _offerScore(ProductDetails product, _SubscriptionPlan plan) {
    if (product is! GooglePlayProductDetails) return 0;

    final offer = _subscriptionOfferForProduct(product);
    if (offer == null) return 0;

    var score = 0;
    final hasFreeTrial = offer.pricingPhases.any(
      (phase) => phase.priceAmountMicros == 0,
    );
    if (hasFreeTrial) score += 100;

    final searchableOfferText = [
      offer.offerId,
      offer.basePlanId,
      ...offer.offerTags,
    ].whereType<String>().join(' ').toLowerCase();

    if (searchableOfferText.contains('trial')) score += 20;
    for (final marker in _preferredTrialMarkers[plan] ?? const <String>[]) {
      if (searchableOfferText.contains(marker)) score += 40;
    }

    return score;
  }

  void _addDebugLine(String line) {
    if (!_showSubscriptionDebug) return;

    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final entry = '$timestamp $line';
    debugPrint('[SubscriptionScreen] $line');

    if (!mounted) {
      _debugLines = _trimDebugLines([..._debugLines, entry]);
      return;
    }

    setState(() {
      _debugLines = _trimDebugLines([..._debugLines, entry]);
    });
  }

  List<String> _trimDebugLines(List<String> lines) {
    if (lines.length <= 80) return lines;
    return lines.sublist(lines.length - 80);
  }

  String _describeProduct(ProductDetails product) {
    final base =
        'id=${product.id}, title=${product.title}, price=${product.price}, '
        'raw=${product.rawPrice}, currency=${product.currencyCode}, '
        'type=${product.runtimeType}';

    if (product is! GooglePlayProductDetails) return base;

    final offer = _subscriptionOfferForProduct(product);
    if (offer == null) {
      return '$base, offer=null, offerToken=${_shortToken(product.offerToken)}';
    }

    final phases = offer.pricingPhases
        .map(
          (phase) =>
              '${phase.formattedPrice}/${phase.billingPeriod}/'
              'cycles=${phase.billingCycleCount}/'
              'micros=${phase.priceAmountMicros}',
        )
        .join(' | ');

    return '$base, subIndex=${product.subscriptionIndex}, '
        'basePlan=${offer.basePlanId}, offerId=${offer.offerId ?? 'null'}, '
        'tags=${offer.offerTags.join(',')}, '
        'offerToken=${_shortToken(product.offerToken)}, phases=[$phases]';
  }

  String _shortToken(String? token) {
    if (token == null || token.isEmpty) return 'null';
    if (token.length <= 12) return token;
    return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceText = isDark ? Colors.white : Colors.black87;
    final mutedText = isDark ? Colors.white70 : Colors.black.withAlpha(153);
    final selectedPlanHasTrial = _hasFreeTrial(
      _preferredProductForPlan(_selectedPlan),
    );
    final selectedProduct = _preferredProductForPlan(_selectedPlan);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Gwen Plus',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF191A2A),
                          Color(0xFF1F2933),
                          Color(0xFF172826),
                        ]
                      : const [
                          Color(0xFFF1EEFF),
                          Color(0xFFF9F7F1),
                          Color(0xFFE9F6F2),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Unlock unlimited access to all features',
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: surfaceText,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withAlpha(128)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/icon3.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      _BenefitLine(
                        icon: Icons.chat_bubble_rounded,
                        text: 'Chat with Gwen from supportive app moments',
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _BenefitLine(
                        icon: Icons.favorite_rounded,
                        text: 'Gentle anxiety support when you need it',
                        color: Colors.pink.shade300,
                      ),
                      const SizedBox(height: 12),
                      _BenefitLine(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Personalized reflections and next steps',
                        color: Colors.teal.shade500,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        selectedPlanHasTrial
                            ? 'Start with a 3 day trial'
                            : 'Choose a plan to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: mutedText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PlanOption(
                        title: 'Monthly',
                        price: _priceForPlan(_SubscriptionPlan.monthly),
                        subtitle: _subtitleForPlan(_SubscriptionPlan.monthly),
                        isSelected: _selectedPlan == _SubscriptionPlan.monthly,
                        primaryColor: primaryColor,
                        surfaceText: surfaceText,
                        mutedText: mutedText,
                        onTap: () {
                          setState(() {
                            _selectedPlan = _SubscriptionPlan.monthly;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _PlanOption(
                        title: 'Yearly',
                        price: _priceForPlan(_SubscriptionPlan.yearly),
                        subtitle: _subtitleForPlan(_SubscriptionPlan.yearly),
                        badge: 'Best value',
                        isSelected: _selectedPlan == _SubscriptionPlan.yearly,
                        primaryColor: primaryColor,
                        surfaceText: surfaceText,
                        mutedText: mutedText,
                        onTap: () {
                          setState(() {
                            _selectedPlan = _SubscriptionPlan.yearly;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_isLoadingProducts || _isPurchasePending)
                              ? null
                              : _buySelectedPlan,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _isPurchasePending
                                ? 'Processing...'
                                : _isLoadingProducts
                                ? 'Loading...'
                                : selectedPlanHasTrial
                                ? 'Try for free'
                                : 'Continue',
                          ),
                        ),
                      ),
                      if (_storeMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _storeMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedText, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Cancel anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FooterLink(
                  label: 'Restore purchase',
                  color: mutedText,
                  onTap: _restorePurchase,
                ),
                const SizedBox(height: 6),
                _FooterLink(
                  label: 'Terms and Conditions',
                  color: mutedText,
                  onTap: _openTerms,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 10),
                  _FooterLink(
                    label: 'Skip',
                    color: mutedText.withAlpha(120),
                    onTap: _skipForTesting,
                  ),
                ],
                if (_showSubscriptionDebug) ...[
                  const SizedBox(height: 16),
                  _SubscriptionDebugPanel(
                    lines: [
                      'selectedPlan=${_selectedPlan.name}',
                      'selectedHasTrial=$selectedPlanHasTrial',
                      'selectedProduct=${selectedProduct == null ? 'null' : _describeProduct(selectedProduct)}',
                      'storeAvailable=$_isStoreAvailable',
                      'loading=$_isLoadingProducts',
                      'purchasePending=$_isPurchasePending',
                      'openChatAfterNextPurchaseUpdate=$_openChatAfterNextPurchaseUpdate',
                      'productsById=${_productsById.map((key, value) => MapEntry(key, value.length))}',
                      if (_storeMessage != null) 'storeMessage=$_storeMessage',
                      ..._debugLines.reversed,
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SubscriptionPlan {
  monthly(price: '\$5.99', periodLabel: 'per month'),
  yearly(price: '\$49.99', periodLabel: 'per year');

  final String price;
  final String periodLabel;

  const _SubscriptionPlan({required this.price, required this.periodLabel});
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final Color primaryColor;
  final Color surfaceText;
  final Color mutedText;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.primaryColor,
    required this.surfaceText,
    required this.mutedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBackground = primaryColor.withAlpha(24);
    final borderColor = isSelected
        ? primaryColor
        : Theme.of(context).dividerColor.withAlpha(102);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBackground : Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? primaryColor : mutedText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: surfaceText,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: TextStyle(
                color: surfaceText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SubscriptionDebugPanel extends StatelessWidget {
  final List<String> lines;

  const _SubscriptionDebugPanel({required this.lines});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withAlpha(82)
            : Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black.withAlpha(31),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription debug',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            lines.join('\n'),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              height: 1.35,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _BenefitLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
