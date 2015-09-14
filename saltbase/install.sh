set -o errexit
set -o nounset
set -o pipefail

LINODE_SALT_ROOT=$(dirname "${BASH_SOURCE}")
readonly LINODE_SALT_ROOT

KUBE_VERSION="$1"
readonly KUBE_VERSION

# Create a temp dir for untaring
KUBE_TEMP=$(mktemp -d -t kubernetes.XXXXXX)
trap 'rm -rf "${KUBE_TEMP}"' EXIT

readonly SALTDIRS=(salt pillar)
mkdir -p /srv/salt-overlay
for dir in "${SALTDIRS[@]}"; do
  cp -v -r "$LINODE_SALT_ROOT/$dir" "/srv/salt-overlay/$dir"
done

wget "https://github.com/kubernetes/kubernetes/releases/download/$KUBE_VERSION/kubernetes.tar.gz" -O "$KUBE_TEMP/kubernetes.tar.gz"
wget "https://github.com/yanatan16/kubernetes/archive/salt-linode-support.tar.gz" -O "$KUBE_TEMP/kubernetes-source.tar.gz"

tar xzvf "$KUBE_TEMP/kubernetes.tar.gz" -C "$KUBE_TEMP"
tar xzvf "$KUBE_TEMP/kubernetes-source.tar.gz" -C "$KUBE_TEMP"
$KUBE_TEMP/kubernetes-salt-linode-support/cluster/saltbase/install.sh "$KUBE_VERSION" "$KUBE_TEMP/kubernetes/server/kubernetes-server-linux-amd64.tar.gz"

echo "Download flannel release ..."
FLANNEL_VERSION=${FLANNEL_VERSION:-"0.5.3"}
echo "Flannel version is $FLANNEL_VERSION"
if [ ! -f flannel.tar.gz ] ; then
  curl -L  https://github.com/coreos/flannel/releases/download/v${FLANNEL_VERSION}/flannel-${FLANNEL_VERSION}-linux-amd64.tar.gz -o flannel.tar.gz
  tar xzf flannel.tar.gz
fi
cp flannel-${FLANNEL_VERSION}/flanneld /srv/salt/kube-bins