import { Mediainfo } from "../lib/mediainfo";

/**
 * Function to get the DV profile of a media file using the mediainfo container
 * This must be run using a privileged container of FileFlows
 * @author:  @riweston
 * @param:   {string} dvheProfile - Profile name e.g. 'dvhe.07'
 * @output:  return1 - If the profile is not found
 * @output:  return2 - If the profile is found
 */

function Script(dvheProfile) {
  try {
    // copy the file into temporary directory
    let wf = Flow.CopyToTemp();
    let shortFile = wf.substring(
      wf.lastIndexOf(Flow.IsWindows ? "\\" : "/") + 1
    );
    let output =
      Flow.NewGuid() +
      "." +
      shortFile.substring(shortFile.lastIndexOf(".") + 1);
    let tempPath = Flow.TempPathHost;

    Logger.ILog("ShortFile: " + shortFile);
    Logger.ILog("Output: " + output);
    Logger.ILog("TempPath: " + tempPath);

    // run the mediainfo container
    let mediaInfo = new Mediainfo(tempPath, shortFile);
    let process = mediaInfo.runDockerCommand();

    if (process.standardOutput) {
      const output = process.standardOutput;
      Logger.ILog("Standard Output: " + output);

      // check for any tracks have the key HDR_Format_Profile and a value with $dvheProfile in it
      const dvhe = mediaInfo.findDvheProfile(output, dvheProfile);
      if (dvhe) {
        Logger.ILog(`DVHE ${dvheProfile} profile found`);
        return 2;
      } else {
        Logger.ILog(`DVHE ${dvheProfile} profile not found`);
        return 1;
      }
    } else {
      Logger.ELog("Error: " + process.standardError);
      return -1;
    }
  } catch (e) {
    Logger.ELog("Error: " + e);
    return -1;
  }
}
