"use strict";

import { config, library, dom } from "@fortawesome/fontawesome-svg-core";
import {
  faPlay,
  faEraser,
  faAlignLeft,
  faCog,
  faQuestion,
  faCodeBranch,
  faCaretRight,
  faCaretDown,
} from "@fortawesome/pro-solid-svg-icons";
import {
  faCheck,
  faFolderTree,
  faTable,
  faQuestionCircle,
  faFileImport,
  faCommentAltSmile,
  faAt,
  faDonate,
  faHeart,
} from "@fortawesome/pro-regular-svg-icons";
import {
  faFileCode,
  faMonitorHeartRate,
} from "@fortawesome/pro-light-svg-icons";
import { faSpinnerThird } from "@fortawesome/pro-duotone-svg-icons";
import { faSwift, faGithub } from "@fortawesome/free-brands-svg-icons";

config.searchPseudoElements = true;
library.add(
  faPlay,
  faEraser,
  faAlignLeft,
  faCog,
  faQuestion,
  faCodeBranch,
  faCaretRight,
  faCaretDown,

  faCheck,
  faFolderTree,
  faTable,
  faQuestionCircle,
  faFileImport,
  faCommentAltSmile,
  faAt,
  faDonate,
  faHeart,

  faFileCode,
  faMonitorHeartRate,

  faSpinnerThird,

  faSwift,
  faGithub
);
dom.watch();
