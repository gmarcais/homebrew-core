class ServiceWeaver < Formula
  desc "Programming framework for writing and deploying cloud applications"
  homepage "https://serviceweaver.dev/"
  license "Apache-2.0"

  stable do
    url "https://github.com/ServiceWeaver/weaver/archive/refs/tags/v0.24.6.tar.gz"
    sha256 "15b34f1539b6a84f8783009a2e8ce98bb12c9a0c0ba70b4ff055e4a8a3406e10"

    resource "weaver-gke" do
      url "https://github.com/ServiceWeaver/weaver-gke/archive/refs/tags/v0.24.4.tar.gz"
      sha256 "97e2bd35b997bc65f824fb1b2eb6500f8ba97d444cc7565be80e61005c462848"
    end
  end

  # Upstream only creates releases for x.x.0 but said that we should use the
  # latest tagged version, regardless of whether there is a GitHub release.
  # With that in mind, we check the Git tags and ignore whether the version is
  # the "latest" release on GitHub.
  # See: https://github.com/ServiceWeaver/weaver/issues/603#issuecomment-1722048623
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "d378f7b1ff8ae4719858eedbc6d78e5d00684971f7d2a7c351c33013287fe93a"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "d6937aac2942e3d6c88fb78d7729d532a1ceb98a8610ed46ac5f85a631e6493e"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "b1bdc4661b9ee6ab7adcdc6eb0854a31776fe3dec6d361f4d31952c4d58a7ade"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "e73451984aa721536c5f7c6f283376f6e6c942b9048d78fe3b9ff633d18a0090"
    sha256 cellar: :any_skip_relocation, sonoma:         "d0bc34988de136c816d13baaffee9d5ead9031e93520d2dbccb34196081ea3ef"
    sha256 cellar: :any_skip_relocation, ventura:        "431b577cfd66847b9ea40bef417154a46b07cdb12da6da52601a17a67585d7a4"
    sha256 cellar: :any_skip_relocation, monterey:       "a473b9444dff01241e26bffa68b90c14e91b50edc42326acd8e28e74e3f3ec9b"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "062225ad3c511c18e076c0cecdc2aaeddb38da8ddc1c39599ae74bbb06630b6a"
  end

  head do
    url "https://github.com/ServiceWeaver/weaver.git", branch: "main"

    resource "weaver-gke" do
      url "https://github.com/ServiceWeaver/weaver-gke.git", branch: "main"
    end
  end

  depends_on "go" => :build

  conflicts_with "weaver", because: "both install a `weaver` binary"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"weaver"), "./cmd/weaver"
    resource("weaver-gke").stage do
      ["weaver-gke", "weaver-gke-local"].each do |f|
        system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/f), "./cmd/#{f}"
      end
    end
  end

  test do
    output = shell_output("#{bin}/weaver single status")
    assert_match "DEPLOYMENTS", output

    gke_output = shell_output("#{bin}/weaver gke status 2>&1", 1)
    assert_match "gcloud not installed", gke_output

    gke_local_output = shell_output("#{bin}/weaver gke-local status 2>&1", 1)
    assert_match "connect: connection refused", gke_local_output
  end
end
