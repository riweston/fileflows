// Tests for lib/mediainfo.js using Jest

const MediaInfo = require("./mediainfo");

describe("MediaInfo", () => {
  describe("validateJson", () => {
    it("should return true if the JSON is valid", () => {
      const json = '{"media": {"track": [{"HDR_Format_Profile": "dvhe.07"}]}}';
      const mediaInfo = new MediaInfo("tmpPath", "shortFile");
      const result = mediaInfo.validateJson(json);
      expect(result).toEqual({
        media: { track: [{ HDR_Format_Profile: "dvhe.07" }] },
      });
    });
    it("should throw an error if the JSON is invalid", () => {
      const json = "invalid json";
      const mediaInfo = new MediaInfo();
      expect(() => mediaInfo.validateJson(json)).toThrow("JSON is invalid");
    });
  });
  describe("findDvheProfile", () => {
    it("should return true if the profile is found", () => {
      const json = '{"media": {"track": [{"HDR_Format_Profile": "dvhe.07"}]}}';
      const profile = "dvhe.07";
      const mediaInfo = new MediaInfo();
      const result = mediaInfo.findDvheProfile(json, profile);
      expect(result).toBe(true);
    });
    it("should return false if the profile is not found", () => {
      const json = '{"media": {"track": [{"HDR_Format_Profile": "dvhe.07"}]}}';
      const profile = "dvhe.08";
      const mediaInfo = new MediaInfo();
      const result = mediaInfo.findDvheProfile(json, profile);
      expect(result).toBe(false);
    });
  });
});
