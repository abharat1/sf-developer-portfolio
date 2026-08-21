import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getProjects from '@salesforce/apex/ProjectController.getProjects';
import refreshProjectStats from '@salesforce/apex/ProjectController.refreshProjectStats';
import logVisitAndGetCount from '@salesforce/apex/ProjectController.logVisitAndGetCount';
import isCurrentUserGuest from '@salesforce/apex/ProjectController.isCurrentUserGuest';

export default class ProjectGallery extends LightningElement {
    allProjects = [];
    activeFilter = 'All';
    visitCount;
    isLoading = true;
    errorMessage;
    wiredProjectsResult;
    isGuest = false;

    @wire(isCurrentUserGuest)
    wiredIsGuest({ data }) {
        // Default to treating the visitor as a guest until we know
        // otherwise - fail closed, not open, on a public-facing action.
        this.isGuest = data === undefined ? true : data;
    }

    @wire(getProjects)
    wiredProjects(result) {
        this.wiredProjectsResult = result;
        this.isLoading = false;
        if (result.data) {
            this.allProjects = result.data.map((p) => this.decorateProject(p));
            this.errorMessage = undefined;
        } else if (result.error) {
            this.errorMessage = this.reduceError(result.error);
        }
    }

    connectedCallback() {
        const sessionId = this.getOrCreateSessionId();
        logVisitAndGetCount({ pageViewed: 'Portfolio Home', sessionId })
            .then((count) => {
                this.visitCount = count;
            })
            .catch((error) => {
                // Visit logging failing shouldn't block the page from rendering
                // eslint-disable-next-line no-console
                console.error('Visit logging failed', error);
            });
    }

    decorateProject(project) {
        const tags = project.Tech_Stack__c
            ? project.Tech_Stack__c.split(',').map((t) => t.trim())
            : [];
        return {
            ...project,
            tags,
            formattedLastCommit: project.Last_Commit_Date__c
                ? new Date(project.Last_Commit_Date__c).toLocaleDateString()
                : 'Not yet synced'
        };
    }

    get filterOptions() {
        const tagSet = new Set();
        this.allProjects.forEach((p) => p.tags.forEach((t) => tagSet.add(t)));
        return ['All', ...Array.from(tagSet).sort()];
    }

    get filteredProjects() {
        if (this.activeFilter === 'All') {
            return this.allProjects;
        }
        return this.allProjects.filter((p) => p.tags.includes(this.activeFilter));
    }

    get hasProjects() {
        return this.filteredProjects.length > 0;
    }

    get canRefreshStats() {
        return !this.isGuest;
    }

    handleFilterChange(event) {
        this.activeFilter = event.currentTarget.dataset.filter;
    }

    handleRefreshStats(event) {
        const projectId = event.currentTarget.dataset.id;
        refreshProjectStats({ projectId })
            .then(() => refreshApex(this.wiredProjectsResult))
            .catch((error) => {
                this.errorMessage = this.reduceError(error);
            });
    }

    getOrCreateSessionId() {
        // Artifacts/LWC context note: in a real org this can safely use
        // sessionStorage. Kept as an in-memory fallback here in case this
        // component is ever previewed somewhere that restricts storage.
        let sessionId;
        try {
            sessionId = window.sessionStorage.getItem('portfolioSessionId');
            if (!sessionId) {
                sessionId = this.generateId();
                window.sessionStorage.setItem('portfolioSessionId', sessionId);
            }
        } catch (e) {
            sessionId = this.generateId();
        }
        return sessionId;
    }

    generateId() {
        return 'sess-' + Math.random().toString(36).substring(2, 15);
    }

    reduceError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        return 'An unexpected error occurred.';
    }
}