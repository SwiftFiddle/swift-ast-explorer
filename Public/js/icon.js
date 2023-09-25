"use strict";

import { library, dom } from "@fortawesome/fontawesome-svg-core";
import {
  faPlay,
  faEraser,
  faAlignLeft,
  faCog,
  faQuestion,
  faCodeBranch,
  faCaretRight,
  faCaretDown,
  faHeart,
} from "@fortawesome/pro-solid-svg-icons";
import {
  faCheck,
  faListTree,
  faTable,
  faQuestionCircle,
  faFileImport,
  faMessageSmile,
  faAt,
} from "@fortawesome/pro-regular-svg-icons";
import {
  faFileCode,
  faMonitorHeartRate,
} from "@fortawesome/pro-light-svg-icons";
import { faSpinnerThird } from "@fortawesome/pro-duotone-svg-icons";
import { faSwift, faGithub } from "@fortawesome/free-brands-svg-icons";

library.add(
  faPlay,
  faEraser,
  faAlignLeft,
  faCog,
  faQuestion,
  faCodeBranch,
  faCaretRight,
  faCaretDown,
  faHeart,

  faCheck,
  faListTree,
  faTable,
  faQuestionCircle,
  faFileImport,
  faMessageSmile,
  faAt,

  faFileCode,
  faMonitorHeartRate,

  faSpinnerThird,

  faSwift,
  faGithub
);
dom.watch();
