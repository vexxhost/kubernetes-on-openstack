#cloud-config
datasource:
 OpenStack:
  metadata_urls: ["http://169.254.169.254"]
  max_wait: -1
  timeout: 10
  retries: 5

repo_update: true
repo_upgrade: all
package_upgrade: true

apt:
  preserve_sources_list: true
  sources:
    kubernetes.list:
      source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
      key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        mQENBF/Jfl4BCADTPUXdkNu057X+P3STVxCzJpU2Mn+tUamKdSdVambGeYFINcp/
        EGwNGhdb0a1BbHs1SWYZbzwh4d6+p3k4ABzVMO+RpMu/aBx9E5aOn5c8GzHjZ/VE
        aheqLLhSUcSCzChSZcN5jz0hTGhmAGaviMt6RMzSfbIhZPj1kDzBiGd0Qwd/rOPn
        Jr4taPruR3ecBjhHti1/BMGd/lj0F7zQnCjp7PrqgpEPBT8jo9wX2wvOyXswSI/G
        sfbFiaOJfDnYengaEg8sF+u3WOs0Z20cSr6kS76KHpTfa3JjYsfHt8NDw8w4e3H8
        PwQzNiRP9tXeMASKQz3emMj/ek6HxjihY9qFABEBAAG0umdMaW51eCBSYXB0dXJl
        IEF1dG9tYXRpYyBTaWduaW5nIEtleSAoLy9kZXBvdC9nb29nbGUzL3Byb2R1Y3Rp
        b24vYm9yZy9jbG91ZC1yYXB0dXJlL2tleXMvY2xvdWQtcmFwdHVyZS1wdWJrZXlz
        L2Nsb3VkLXJhcHR1cmUtc2lnbmluZy1rZXktMjAyMC0xMi0wMy0xNl8wOF8wNS5w
        dWIpIDxnbGludXgtdGVhbUBnb29nbGUuY29tPokBKAQTAQgAHAUCX8l+XgkQi1fF
        woNvS+sCGwMFCQPDCrACGQEAAEF6CACaekro6aUJJd3mVtrtLOOewV8et1jep5ew
        mpOrew/pajRVBeIbV1awVn0/8EcenFejmP6WFcdCWouDVIS/QmRFQV9N6YXN8Piw
        alrRV3bTKFBHkwa1cEH4AafCGo0cDvJb8N3JnM/Rmb1KSGKr7ZXpmkLtYVqr6Hgz
        l+snrlH0Xwsl5r3SyvqBgvRYTQKZpKqmBEd1udieVoLSF988kKeNDjFa+Q1SjZPG
        W+XukgE8kBUbSDx8Y8q6Cszh3VVY+5JUeqimRgJ2ADY2/3lEtAZOtmwcBlhY0cPW
        Vqga14E7kTGSWKC6W96Nfy9K7L4Ypp8nTMErus181aqwwNfMqnpnuQENBF/Jfl4B
        CADDSh+KdBeNjIclVVnRKt0QT5593yF4WVZt/TgNuaEZ5vKknooVVIq+cJIfY/3l
        Uqq8Te4dEjodtFyKe5Xuego6qjzs8TYFdCAHXpXRoUolT14m+qkJ8rhSrpN0TxIj
        WJbJdm3NlrgTam5RKJw3ShypNUxyolnHelXxqyKDCkxBSDmR6xcdft3wdQl5IkIA
        wxe6nywmSUtpndGLRJdJraJiaWF2IBjFNg3vTEYj4eoehZd4XrvEyLVrMbKZ5m6f
        1o6QURuzSrUH9JT/ivZqCmhPposClXXX0bbi9K0Z/+uVyk6v76ms3O50rIq0L0Ye
        hM8G++qmGO421+0qCLkdD5/jABEBAAGJAR8EGAEIABMFAl/Jfl4JEItXxcKDb0vr
        AhsMAAAbGggAw7lhSWElZpGV1SI2b2K26PB93fVI1tQYV37WIElCJsajF+/ZDfJJ
        2d6ncuQSleH5WRccc4hZfKwysA/epqrCnwc7yKsToZ4sw8xsJF1UtQ5ENtkdArVi
        BJHS4Y2VZ5DEUmr5EghGtZFh9a6aLoeMVM/nrZCLstDVoPKEpLokHu/gebCwfT/n
        9U1dolFIovg6eKACl5xOx+rzcAVp7R4P527jffudz3dKMdLhPrstG0w5YbyfPPwW
        MOPp+kUF45eYdR7kKKk09VrJNkEGJ0KQQ6imqR1Tn0kyu4cvkfqnCUF0rrn7CdBq
        LSCv1QRhgr6TChQf7ynWsPz5gGdVjh3tIw==
        =dsvF
        -----END PGP PUBLIC KEY BLOCK-----
write_files:
-   content: |
        apiVersion: kubeadm.k8s.io/v1beta1
        kind: InitConfiguration
        bootstrapTokens:
        - groups:
          - system:bootstrappers:kubeadm:default-node-token
          token: ${bootstrap_token}
          ttl: 24h0m0s
          usages:
          - signing
          - authentication
        localAPIEndpoint:
          advertiseAddress: ${internal_ip}
          bindPort: 6443
        nodeRegistration:
          criSocket: /run/containerd/containerd.sock
          kubeletExtraArgs:
            container-runtime: remote
            container-runtime-endpoint: unix:///run/containerd/containerd.sock
          taints:
          - effect: NoSchedule
            key: node-role.kubernetes.io/master
        ---
        apiVersion: kubeadm.k8s.io/v1beta1
        kind: ClusterConfiguration
        apiServer:
          certSANs:
          - ${external_ip}
          - ${internal_ip}
          extraArgs:
            external-hostname: ${external_ip}
          timeoutForControlPlane: 4m0s
        certificatesDir: /etc/kubernetes/pki
        clusterName: kubernetes
        controlPlaneEndpoint: ""
        controllerManager:
          extraArgs:
        dns:
          type: CoreDNS
        etcd:
          local:
            dataDir: /var/lib/etcd
        imageRepository: k8s.gcr.io
        kubernetesVersion: v${kubernetes_version}
        networking:
          dnsDomain: cluster.local
          podSubnet: "${pod_subnet}"
          serviceSubnet: 10.96.0.0/16
        scheduler: {}
        ---
        apiVersion: kubeproxy.config.k8s.io/v1alpha1
        kind: KubeProxyConfiguration
        bindAddress: 0.0.0.0
        clientConnection:
          acceptContentTypes: ""
          burst: 10
          contentType: application/vnd.kubernetes.protobuf
          kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
          qps: 5
        clusterCIDR: ""
        configSyncPeriod: 15m0s
        conntrack:
          max: null
          maxPerCore: 32768
          min: 131072
          tcpCloseWaitTimeout: 1h0m0s
          tcpEstablishedTimeout: 24h0m0s
        enableProfiling: false
        healthzBindAddress: 0.0.0.0:10256
        hostnameOverride: ""
        iptables:
          masqueradeAll: false
          masqueradeBit: 14
          minSyncPeriod: 0s
          syncPeriod: 30s
        ipvs:
          excludeCIDRs: null
          minSyncPeriod: 0s
          scheduler: ""
          syncPeriod: 30s
        metricsBindAddress: 127.0.0.1:10249
        mode: ipvs
        nodePortAddresses: null
        oomScoreAdj: -999
        portRange: ""
        resourceContainer: /kube-proxy
        udpIdleTimeout: 250ms
        ---
        kind: KubeletConfiguration
        apiVersion: kubelet.config.k8s.io/v1beta1
        address: 0.0.0.0
        authentication:
          anonymous:
            enabled: false
          webhook:
            cacheTTL: 2m0s
            enabled: true
          x509:
            clientCAFile: /etc/kubernetes/pki/ca.crt
        authorization:
          mode: Webhook
          webhook:
            cacheAuthorizedTTL: 5m0s
            cacheUnauthorizedTTL: 30s
        cgroupDriver: systemd
        cgroupRoot: /
        cgroupsPerQOS: true
        clusterDNS:
        - 10.96.0.10
        clusterDomain: cluster.local
        configMapAndSecretChangeDetectionStrategy: Watch
        containerLogMaxFiles: 5
        containerLogMaxSize: 10Mi
        contentType: application/vnd.kubernetes.protobuf
        cpuCFSQuota: true
        cpuCFSQuotaPeriod: 100ms
        cpuManagerPolicy: none
        cpuManagerReconcilePeriod: 10s
        enableControllerAttachDetach: true
        enableDebuggingHandlers: true
        enforceNodeAllocatable:
        - pods
        eventBurst: 10
        eventRecordQPS: 5
        evictionHard:
          imagefs.available: 15%
          memory.available: 100Mi
          nodefs.available: 10%
          nodefs.inodesFree: 5%
        evictionPressureTransitionPeriod: 5m0s
        failSwapOn: true
        fileCheckFrequency: 20s
        hairpinMode: promiscuous-bridge
        healthzBindAddress: 127.0.0.1
        healthzPort: 10248
        httpCheckFrequency: 20s
        imageGCHighThresholdPercent: 85
        imageGCLowThresholdPercent: 80
        imageMinimumGCAge: 2m0s
        iptablesDropBit: 15
        iptablesMasqueradeBit: 14
        kubeAPIBurst: 10
        kubeAPIQPS: 5
        makeIPTablesUtilChains: true
        maxOpenFiles: 1000000
        maxPods: 110
        nodeLeaseDurationSeconds: 40
        nodeStatusReportFrequency: 10s
        nodeStatusUpdateFrequency: 10s
        oomScoreAdj: -999
        podPidsLimit: -1
        port: 10250
        registryBurst: 10
        registryPullQPS: 5
        resolvConf: /etc/resolv.conf
        rotateCertificates: true
        runtimeRequestTimeout: 15m0s
        serializeImagePulls: false
        staticPodPath: /etc/kubernetes/manifests
        streamingConnectionIdleTimeout: 4h0m0s
        syncFrequency: 1m0s
        volumeStatsAggPeriod: 1m0s
    path: /etc/kubernetes/kubeadm.yaml
    owner: root:root
    permissions: '0600'
-   content: |
        apiVersion: v1
        data:
          Corefile: |
            .:53 {
                errors
                health {
                  lameduck 5s
                }
                ready
                kubernetes cluster.local in-addr.arpa ip6.arpa {
                  pods insecure
                  fallthrough in-addr.arpa ip6.arpa
                  ttl 30
                }
                prometheus :9153
                forward . 8.8.8.8 {
                  max_concurrent 1000
                }
                cache 30
                loop
                reload
                loadbalance
            }
        kind: ConfigMap
        metadata:
          name: coredns
          namespace: kube-system
    path: /etc/kubernetes/addons/coredns-hack.yaml
    owner: root:root
    permissions: '0600'
-   content: |
        #!/bin/bash
        set -eu

        # Install Containerd and load all required modules
        curl -sLo /tmp/containerd.tar.gz "https://storage.googleapis.com/cri-containerd-release/cri-containerd-${containerd_version}.linux-amd64.tar.gz"
        tar -C / -xzf /tmp/containerd.tar.gz
        systemctl start containerd
        systemctl enable containerd
        modprobe ip_vs_rr
        modprobe ip_vs_wrr
        modprobe ip_vs_sh
        modprobe ip_vs
        modprobe br_netfilter
        modprobe nf_conntrack_ipv4
        echo '1' > /proc/sys/net/ipv4/ip_forward
        echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
        kubeadm init --config /etc/kubernetes/kubeadm.yaml --skip-token-print
        mkdir -p /root/.kube
        cp -i /etc/kubernetes/admin.conf /root/.kube/config
        mkdir -p /home/ubuntu/.kube
        cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
        chown ubuntu /home/ubuntu/.kube/config

        export KUBECONFIG=/etc/kubernetes/admin.conf
        kubectl apply -f "https://docs.projectcalico.org/archive/v3.15/manifests/calico.yaml"

        kubectl apply -n kube-system  -f "/etc/kubernetes/addons"
        # Install Metrics Server
        # kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.1/components.yaml

        unset KUBECONFIG
    path: /usr/local/bin/init.sh
    owner: root:root
    permissions: '0700'

packages:
  - unzip
  - tar
  - apt-transport-https
  - btrfs-tools
  - util-linux
  - nfs-common
  - [kubernetes-cni, "${kubernetes_cni_version}-00"]
  - [kubelet, "${kubernetes_version}-00"]
  - [kubeadm, "${kubernetes_version}-00"]
  - [kubectl, "${kubernetes_version}-00"]
  - jq
  - ipvsadm
  - socat
  - conntrack
  - ipset
  - libseccomp2

# The addon deployment can be moved out once we have a stable endpoint
runcmd:
  - [ /usr/local/bin/init.sh ]
