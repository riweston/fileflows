/**
 * Class for MediaInfo
 * @name MediaInfo
 */

class MediaInfo {
  tmpPath;
  shortFile;

  constructor(tmpPath, shortFile) {
    this.tmpPath = tmpPath;
    this.shortFile = shortFile;
  }

  /**
   * Function to get JSON output from a media file using the mediainfo container
   * This must be run using a privileged container of FileFlows
   * @returns {string} - JSON output
   * @name MediaInfo#getJson
   */
  runDockerCommand() {
    return Flow.Execute({
      command: "docker",
      argumentList: [
        "run",
        "--rm",
        "-v",
        this.tmpPath + ":/tmp",
        "ghcr.io/riweston/mediainfo",
        "/tmp/" + this.shortFile,
      ],
    });
  }

  /**
   * Helper function to check if a string is valid JSON
   * @param {string} json
   * @name MediaInfo#validateJson
   */
  validateJson(json) {
    try {
      var jsonObj = JSON.parse(json);
      return jsonObj;
      //Logger.ILog("JSON is valid");
    } catch (e) {
      //Logger.ELog("Error: " + e);
      // throw an error if the JSON is invalid
      throw "JSON is invalid";
    }
  }

  /**
   * Function to get the DV profile of a media file using the mediainfo container
   * This must be run using a privileged container of FileFlows
   * @param {string} profile - Profile name - e.g. 'dvhe.07'
   * @returns {boolean}
   * @name MediaInfo#getDvProfile
   */
  findDvheProfile(json, profile) {
    // Check if the JSON is valid
    var jsonObj = this.validateJson(json);

    var dvhe = jsonObj.media.track.find(
      (track) =>
        track.HDR_Format_Profile && track.HDR_Format_Profile.includes(profile)
    );
    if (dvhe) {
      //Logger.ILog("DVHE profile found");
      return true;
    } else {
      //Logger.ILog("DVHE profile not found");
      return false;
    }
  }
}

module.exports = MediaInfo;
