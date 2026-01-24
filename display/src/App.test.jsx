import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from './App'

describe('App', () => {
  it('renders without crashing', () => {
    render(<App />)
    // 로그인 페이지가 렌더링되는지 확인
    expect(screen.getByLabelText('로봇펜 번호')).toBeInTheDocument()
  })
})
