export type VersionManifest = {
  latest: {
    release: string;
    snapshot: string;
  };
  versions: {
    id: string;
    url: string;
  }[];
};

export type Version = {
  downloads: {
    client: {
      sha1: string;
      size: number;
      url: string;
    };
  };
};
