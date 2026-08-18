declare module "@salesforce/apex/ProjectController.getProjects" {
  export default function getProjects(): Promise<any>;
}
declare module "@salesforce/apex/ProjectController.isCurrentUserGuest" {
  export default function isCurrentUserGuest(): Promise<any>;
}
declare module "@salesforce/apex/ProjectController.refreshProjectStats" {
  export default function refreshProjectStats(param: {projectId: any}): Promise<any>;
}
declare module "@salesforce/apex/ProjectController.logVisitAndGetCount" {
  export default function logVisitAndGetCount(param: {pageViewed: any, sessionId: any}): Promise<any>;
}
