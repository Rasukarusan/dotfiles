// 更新チェックはしない (dotfiles に置いた固定版を使う)。receipt の形だけ保つ
export function startDeliveryUpdateCheck() {
  return Promise.resolve({ status: 'unavailable', installedVersion: null, availableVersion: null,
    releaseNotes: null, checkedAt: null, source: null, noticeRequired: false,
    noticeText: null, reason: 'disabled' });
}
