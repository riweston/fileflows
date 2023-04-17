/**
 * Function to process a media file, if it matches the Dolby Vision
 * profile set in the parameters, then convert it to DV profile 8.1
 *
 * This must be run using a privileged container of FileFlows
 *
 * @author @riweston
 * @revision 1
 * @minimumVersion 1.0.0.0
 * @param {string} hostPathPrefix - The path to the runner filesystem e.g. '/volume1/docker/fileflows'
 * @param {string} dvheProfile - Profile name e.g. 'dvhe.07'
 * @output File processed
 */

function Script(hostPathPrefix, dvheProfile) {
  try {
    // copy the file into temporary directory to mount into container
    let wf = Flow.CopyToTemp();
    // get the filename
    let shortFile = wf.substring(
      wf.lastIndexOf(Flow.IsWindows ? "\\" : "/") + 1
    );
    // create the output filename
    let output =
      Flow.NewGuid() +
      "." +
      shortFile.substring(shortFile.lastIndexOf(".") + 1);
    // create the path to the temporary directory on the host filesystem (runner)
    let hostPath = hostPathPrefix + Flow.TempPathHost;

    Logger.ILog("ShortFile: " + shortFile);
    Logger.ILog("Output: " + output);
    Logger.ILog("HostPath: " + hostPath);

    // the container should decide if the file matches the profile and convert it if so
    let process = Flow.Execute({
      command: "docker",
      argumentList: [
        "run",
        "--rm",
        "-v",
        hostPath + ":/opt/media/",
        "ghcr.io/riweston/dovi_tool",
        shortFile,
        dvheProfile,
      ],
    });

    if (process.exitCode === 0) {
      // under normal circumstances, the container will have created a new file in the temporary directory
      // we may as well set the working file to this new file so that it can be processed by the next script
      Logger.ILog("File processed");
      Logger.ILog("Standard Output: " + process.standardOutput);
      let tempFile = Flow.TempPathHost + "/" + shortFile;
      Flow.SetWorkingFile(tempFile);
      return 1;
    } else {
      Logger.ELog("Error: " + process.standardError);
      return -1;
    }
  } catch (e) {
    Logger.ELog("Error: " + e);
    return -1;
  }
}
