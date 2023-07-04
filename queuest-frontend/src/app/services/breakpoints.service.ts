import {Injectable} from '@angular/core';
import {BreakpointObserver, Breakpoints} from "@angular/cdk/layout";
import {Observable} from "rxjs";

export enum BreakPoints {
  xs = '(max-width: 599.98px)',
  sm = '(min-width: 600px) and (max-width: 904.98px)',
  md = '(min-width: 905px) and (max-width: 1239.98px)',
  lg = '(min-width: 1240px) and (max-width: 1439.98px)',
  xl = '(min-width: 1440px)',
}

@Injectable({
  providedIn: 'root'
})
export class BreakpointsService {

  constructor(private responsive: BreakpointObserver) {
  }

  public observe(): Observable<BreakPoints> {
    return new Observable((observer) => {
      this.responsive.observe(BreakPoints.xs).subscribe(result => {
        if (result.matches) observer.next(BreakPoints.xs);
      });
      this.responsive.observe(BreakPoints.sm).subscribe(result => {
        if (result.matches) observer.next(BreakPoints.sm);
      });
      this.responsive.observe(BreakPoints.md).subscribe(result => {
        if (result.matches) observer.next(BreakPoints.md);
      });
      this.responsive.observe(BreakPoints.lg).subscribe(result => {
        if (result.matches) observer.next(BreakPoints.lg);
      });
      this.responsive.observe(BreakPoints.xl).subscribe(result => {
        if (result.matches) observer.next(BreakPoints.xl);
      });
    });
  }

// {

// this.responsive.observe(Breakpoints.Small)
//   .subscribe(result => {
//     if (result.matches) {
//       this.breakpont = `Small`
//     }
//   });
// this.responsive.observe(Breakpoints.Medium)
//   .subscribe(result => {
//     if (result.matches) {
//       this.breakpont = `Medium`
//     }
//   });
// this.responsive.observe(Breakpoints.Large)
//   .subscribe(result => {
//     if (result.matches) {
//       this.breakpont = `Large`
//     }
//   });
// this.responsive.observe(Breakpoints.XLarge)
//   .subscribe(result => {
//     if (result.matches) {
//       this.breakpont = `XLarge`
//     }
//   });
//
// }
}
