import { Component, OnInit } from '@angular/core';
import { ResultService } from '../result.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-result',
  templateUrl: './result.component.html',
  styleUrls: ['./result.component.scss']
})
export class ResultComponent implements OnInit {
  result: any;
  state: String;
  zipcode: String;
  county: String;
  dob: Date;
  household_frequency: String;
  household_frequency_text: String;
  household_amount: Number;
  start_month: Date;
  end_month: Date;
  hra_frequency: String;
  hra_frequency_text: String;
  hra_amount: Number;
  full_hra_type: String;
  taxCredit: String;
  // marketPlace: String;
  // help_text_1: String;
  // help_text_2: String;
  // short_term_plan_text: String;
  // minimum_essential_coverage_text: String;
  // minimum_essential_coverage_link: String;
  // enroll_without_aptc_text: String;
  // help_text_3: String;
  // help_text_4: String;
  // help_text_5: String;
  showUnaffordableQsehraText: boolean = false;
  showAffordableQsehraText: boolean = false;
  showUnaffordableIchraText: boolean = false;
  showAffordableIchraText: boolean = false;
  isIchra: boolean = false;
  isQsehra: boolean = false;
  isMonthlyIncome: boolean = false;
  isAnnualIncome: boolean = false;
  isMonthlyHra: boolean = false;
  isTotalHra: boolean = false;

  residence: String;
  constructor(private resultService: ResultService, private router: Router) {}

  private _hra_type: string | null;
  private _hra_determination: string | null;

  public get hra_type(): string | null {
    return this._hra_type;
  }

  public set hra_type(new_type: string | null) {
    this._hra_type = new_type;
    this.updateHRATypes();
  }

  public get hra_determination(): string | null {
    return this._hra_determination;
  }

  public set hra_determination(new_type: string | null) {
    this._hra_determination = new_type;
    this.updateHRATypes();
  }

  ngOnInit() {
    this.result = this.resultService.results;
    console.log(this.result);
    if (this.result) {
      this.state = this.result.data.state;
      this.zipcode = this.result.data.zipcode;
      this.county = this.result.data.county;
      this.dob = this.result.data.dob;
      this.household_frequency = this.result.data.household_frequency;
      this.household_amount = this.result.data.household_amount;
      this.start_month = this.result.data.start_month;
      this.end_month = this.result.data.end_month;
      this.hra_frequency = this.result.data.hra_frequency;
      this.hra_amount = this.result.data.hra_amount;
      this.hra_type = this.result.data.hra_type;
      this.hra_determination = this.result.data.hra_determination;
      this.residence = [this.state, this.zipcode, this.county]
        .filter(function(val) {
          return val !== null && val !== '';
        })
        .join(' / ');
    } else {
      this.router.navigateByUrl('/home');
    }

    if (this.household_frequency == 'annually') {
      this.household_frequency_text = 'Annual';
      this.isAnnualIncome = true;
    } else if (this.household_frequency == 'monthly') {
      this.household_frequency_text = 'Monthly';
      this.isMonthlyIncome = true;
    }

    if (this.hra_frequency == 'annually') {
      this.hra_frequency_text = 'Total';
      this.isTotalHra = true;
    } else if (this.hra_frequency == 'monthly') {
      this.hra_frequency_text = 'Monthly';
      this.isMonthlyHra = true;
    }

    this.updateHRATypes();
  }

  private updateHRATypes() {
    if (this.hra_type == 'qsehra') {
      this.full_hra_type = 'Qualified Small Employer HRA';
      this.isQsehra = true;
      if (this.hra_determination == 'unaffordable') {
        this.showUnaffordableQsehraText = true;
      } else if (this.hra_determination == 'affordable') {
        this.showAffordableQsehraText = true;
      }
    } else if (this.hra_type == 'ichra') {
      this.isIchra = true;
      this.full_hra_type = 'Individual Coverage HRA';
      if (this.hra_determination == 'unaffordable') {
        this.showUnaffordableIchraText = true;
      } else if (this.hra_determination == 'affordable') {
        this.showAffordableIchraText = true;
      }
    }
  }

  clearResultForm() {
    this.resultService.setFormData(null);
  }
}
