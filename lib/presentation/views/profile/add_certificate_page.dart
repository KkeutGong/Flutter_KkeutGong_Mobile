import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/data/repositories/home/home_repository.dart';
import 'package:kkeutgong_mobile/data/repositories/user/user_certificates_repository.dart';
import 'package:kkeutgong_mobile/domain/models/user/user_certificate.dart';
import 'package:kkeutgong_mobile/gen/assets.gen.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

class AddCertificatePage extends StatefulWidget {
  const AddCertificatePage({super.key});

  @override
  State<AddCertificatePage> createState() => _AddCertificatePageState();
}

class _AddCertificatePageState extends State<AddCertificatePage> {
  final _repo = UserCertificatesRepository();
  final _api = ApiClient();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allCerts = [];
  Set<String> _registeredIds = {};
  String? _adding;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final catalogFuture = _api.get('/catalog/certificates');
      final myFuture = _repo.getMyCertificates();
      final results = await Future.wait([catalogFuture, myFuture]);
      final catalog = (results[0] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final myCerts = results[1] as List<UserCertificate>;
      setState(() {
        _allCerts = catalog;
        _registeredIds = myCerts.map((c) => c.certificateId).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _add(String certificateId) async {
    setState(() => _adding = certificateId);
    try {
      await _repo.addCertificate(certificateId);
      HomeRepository().invalidateCache();
      setState(() {
        _registeredIds = {..._registeredIds, certificateId};
        _adding = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자격증이 추가되었습니다.')),
        );
      }
    } catch (e) {
      setState(() => _adding = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추가 실패: $e')),
        );
      }
    }
  }

  Widget _iconForCert(String iconName, ThemeColors colors) {
    switch (iconName) {
      case 'desktop_mac':
        return Assets.icons.desktopMac.svg(
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      case 'menu_book':
        return Assets.icons.menuBook.svg(
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
      default:
        return Assets.icons.memory.svg(
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.gray20,
      appBar: AppBar(
        backgroundColor: colors.gray0,
        elevation: 0,
        leading: Semantics(
          button: true,
          identifier: 'add-cert-back',
          label: '뒤로 가기',
          child: IconButton(
            icon: Assets.icons.arrowBackIos.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(colors.gray900, BlendMode.srcIn),
            ),
            onPressed: () => Get.back(),
          ),
        ),
        title: Text(
          '자격증 추가',
          style: Typo.headingRegular(context, color: colors.gray900),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('오류: $_error'),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allCerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cert = _allCerts[index];
                    final id = cert['id'] as String;
                    final name = cert['name'] as String;
                    final icon = cert['icon'] as String? ?? 'memory';
                    final isRegistered = _registeredIds.contains(id);
                    final isAdding = _adding == id;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.gray0,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _iconForCert(icon, colors),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: Typo.bodyRegular(
                                  context,
                                  color: colors.gray900),
                            ),
                          ),
                          if (isRegistered)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '등록됨',
                                style: Typo.labelRegular(
                                    context,
                                    color: colors.primaryNormal),
                              ),
                            )
                          else if (isAdding)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Semantics(
                              button: true,
                              identifier: 'add-cert-$id',
                              label: '$name 추가',
                              child: GestureDetector(
                                onTap: () => _add(id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.gray900,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '추가',
                                    style: Typo.labelRegular(
                                        context,
                                        color: colors.gray0),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
