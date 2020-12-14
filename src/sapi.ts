import * as utils from './utils';

/**
 * Function to set sapi
 *
 * @param sapi_csv
 * @param os_version
 */
export async function addSAPI(
  sapi_csv: string,
  os_version: string
): Promise<string> {
  const sapi_list: Array<string> = await utils.CSVArray(sapi_csv);
  let script: string = '\n' + (await utils.stepLog('Setup SAPI', os_version));
  await utils.asyncForEach(sapi_list, async function (sapi: string) {
    sapi = sapi.toLowerCase();
    switch (os_version) {
      case 'linux':
      case 'darwin':
        script += 'add_sapi ' + sapi + '\n';
        break;
      case 'win32':
        script += 'Add-Sapi ' + sapi + '\n';
        break;
    }
  });
  return script;
}
